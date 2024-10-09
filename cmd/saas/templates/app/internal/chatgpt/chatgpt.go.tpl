package chatgpt

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"{{ .serviceName }}/internal/config"
	"{{ .serviceName }}/internal/ratelimiter"
)

// Constants
const (
	maxRetries = 10
)

// StreamResponse represents a chunk of the streaming response
type StreamResponse struct {
	Content string
	Error   error
}

// ChatGPTClient represents a client for interacting with the ChatGPT API
type ChatGPTClient struct {
	endpoint    string
	apiKey      string
	client      *http.Client
	model       string
	rateLimiter *ratelimiter.RateLimiter
}

// Conversation represents a conversation with the ChatGPT API
type Conversation struct {
	CurrentPrompt   string
	PreviousPrompts []string
	Responses       []string
	Metadata        interface{}
}

// ChatGPTService represents a service for managing conversations with the ChatGPT API
type ChatGPTService struct {
	chatGPTClient *ChatGPTClient
	conversations map[string]*Conversation
	mutex         *sync.Mutex
}

// NewChatGPTClient creates a new ChatGPTClient
func NewChatGPTClient(cfg *config.GPT, rateLimiter *ratelimiter.RateLimiter) (*ChatGPTClient, error) {
	log.Println("Initializing ChatGPTClient")
	client := &http.Client{}

	chatGPTClient := &ChatGPTClient{
		endpoint:    cfg.Endpoint,
		apiKey:      cfg.APIKey,
		client:      client,
		model:       cfg.Model,
		rateLimiter: rateLimiter,
	}

	log.Printf("ChatGPTClient initialized with endpoint: %s and model: %s", cfg.Endpoint, cfg.Model)
	return chatGPTClient, nil
}

// GenerateResponse generates a response from the ChatGPT API
func (c *ChatGPTClient) GenerateResponse(prompt string, stream bool, conversationID string) (<-chan StreamResponse, error) {
	log.Printf("GenerateResponse called with prompt: %s, stream: %v, conversationID: %s", prompt, stream, conversationID)

	responseChan := make(chan StreamResponse)

	go func() {
		defer close(responseChan)

		// Prepare the request body once
		requestBody, err := json.Marshal(struct {
			Model       string              `json:"model"`
			Messages    []map[string]string `json:"messages"`
			Temperature float64             `json:"temperature"`
			Stream      bool                `json:"stream"`
		}{
			Model: c.model,
			Messages: []map[string]string{
				{
					"role":    "user",
					"content": prompt,
				},
			},
			Temperature: 0.3,
			Stream:      true, // Always use streaming
		})
		if err != nil {
			log.Printf("Failed to marshal request body: %v", err)
			responseChan <- StreamResponse{Error: fmt.Errorf("failed to marshal request body: %v", err)}
			return
		}

		var attempt int
		for attempt = 0; attempt < maxRetries; attempt++ {
			// Acquire semaphore to limit concurrency
			if err := c.rateLimiter.Semaphore.Acquire(context.Background(), 1); err != nil {
				log.Printf("Error acquiring semaphore: %v", err)
				responseChan <- StreamResponse{Error: err}
				return
			}

			// Wait for rate limiter to allow the next request
			if err := c.rateLimiter.Limiter.Wait(context.Background()); err != nil {
				log.Printf("Rate limiter error: %v", err)
				c.rateLimiter.Semaphore.Release(1)
				responseChan <- StreamResponse{Error: fmt.Errorf("rate limiter error: %v", err)}
				return
			}

			// Create a new HTTP request for each attempt
			req, err := http.NewRequest(http.MethodPost, c.endpoint, bytes.NewBuffer(requestBody))
			if err != nil {
				log.Printf("Failed to create request: %v", err)
				c.rateLimiter.Semaphore.Release(1)
				responseChan <- StreamResponse{Error: fmt.Errorf("failed to create request: %v", err)}
				return
			}

			req.Header.Set("Authorization", "Bearer "+c.apiKey)
			req.Header.Set("Content-Type", "application/json")

			// Send the request
			resp, err := c.client.Do(req)
			c.rateLimiter.Semaphore.Release(1) // Release semaphore after request is sent

			if err != nil {
				log.Printf("Failed to send request: %v", err)
				// Retry on network errors
				if attempt < maxRetries-1 {
					backoff := time.Duration(1<<attempt) * time.Second // Exponential backoff
					log.Printf("Retrying after %v due to network error", backoff)
					time.Sleep(backoff)
					continue
				}
				responseChan <- StreamResponse{Error: fmt.Errorf("failed to send request: %v", err)}
				return
			}

			// Check for successful response
			if resp.StatusCode == http.StatusOK {
				// Process the response
				defer resp.Body.Close()
				scanner := bufio.NewScanner(resp.Body)
				buf := make([]byte, 0, 64*1024)
				scanner.Buffer(buf, 1024*1024)

				for scanner.Scan() {
					line := scanner.Text()
					line = strings.TrimSpace(line)
					if line == "" {
						continue
					}

					if !strings.HasPrefix(line, "data: ") {
						continue
					}

					data := strings.TrimPrefix(line, "data: ")
					if data == "[DONE]" {
						break
					}

					var streamResponse struct {
						Choices []struct {
							Delta struct {
								Content string `json:"content"`
							} `json:"delta"`
						} `json:"choices"`
					}
					if err := json.Unmarshal([]byte(data), &streamResponse); err != nil {
						responseChan <- StreamResponse{Error: fmt.Errorf("error unmarshalling stream data: %v", err)}
						continue
					}

					if len(streamResponse.Choices) > 0 && streamResponse.Choices[0].Delta.Content != "" {
						responseChan <- StreamResponse{Content: streamResponse.Choices[0].Delta.Content}
					}
				}

				if err := scanner.Err(); err != nil {
					responseChan <- StreamResponse{Error: fmt.Errorf("error reading stream: %v", err)}
				}

				return // Successfully processed the response
			}

			// Handle non-200 responses
			body, _ := io.ReadAll(resp.Body)
			resp.Body.Close()
			log.Printf("Received non-200 response: %d - %s", resp.StatusCode, string(body))

			// Check for rate limiting or server errors
			if resp.StatusCode == http.StatusTooManyRequests || resp.StatusCode >= 500 {
				// Retry on rate limiting or server errors
				if attempt < maxRetries-1 {
					var backoff time.Duration
					if resp.StatusCode == http.StatusTooManyRequests {
						// Check for 'Retry-After' header
						retryAfter := resp.Header.Get("Retry-After")
						if retryAfter != "" {
							if retrySeconds, err := strconv.Atoi(retryAfter); err == nil {
								backoff = time.Duration(retrySeconds) * time.Second
							}
						}
					}
					if backoff == 0 {
						// Exponential backoff
						backoff = time.Duration(1<<attempt) * time.Second
					}
					log.Printf("Retrying after %v due to status code %d", backoff, resp.StatusCode)
					time.Sleep(backoff)
					continue
				}
			}

			// Other errors are not retried
			responseChan <- StreamResponse{Error: fmt.Errorf("received non-200 response: %d - %s", resp.StatusCode, string(body))}
			return
		}

		// If all retries failed
		responseChan <- StreamResponse{Error: fmt.Errorf("max retries exceeded")}
	}()

	return responseChan, nil
}

// MustNewChatGPTService creates a new ChatGPTService or panics if an error occurs
func MustNewChatGPTService(cfg *config.GPT, rateLimiter *ratelimiter.RateLimiter) *ChatGPTService {
	log.Println("Creating new ChatGPTService")
	chatGPTClient, err := NewChatGPTClient(cfg, rateLimiter)
	if err != nil {
		log.Panicf("Failed to create ChatGPTClient: %v", err)
	}
	return &ChatGPTService{
		chatGPTClient: chatGPTClient,
		conversations: make(map[string]*Conversation),
		mutex:         &sync.Mutex{},
	}
}

// StartConversation starts a new conversation
func (s *ChatGPTService) StartConversation(conversationID string, metadata interface{}) {
	log.Printf("Starting new conversation with ID: %s", conversationID)
	conversation := &Conversation{
		Metadata: metadata,
	}
	s.mutex.Lock()
	s.conversations[conversationID] = conversation
	s.mutex.Unlock()
	log.Printf("Conversation started: %s", conversationID)
}

// ProcessPrompt processes a prompt and returns the response
func (s *ChatGPTService) ProcessPrompt(conversationID string, prompt string, stream bool) (string, error) {
	log.Printf("Processing prompt for conversation: %s", conversationID)
	s.mutex.Lock()
	conversation, ok := s.conversations[conversationID]
	s.mutex.Unlock()
	if !ok {
		log.Printf("Conversation not found, starting new conversation: %s", conversationID)
		s.StartConversation(conversationID, nil)
		conversation = s.conversations[conversationID]
	}

	conversation.PreviousPrompts = append(conversation.PreviousPrompts, conversation.CurrentPrompt)
	conversation.CurrentPrompt = prompt

	responseChan, err := s.chatGPTClient.GenerateResponse(prompt, stream, conversationID)
	if err != nil {
		log.Printf("Error generating response: %v", err)
		return "", err
	}

	var fullResponse strings.Builder
	for resp := range responseChan {
		if resp.Error != nil {
			log.Printf("Error in stream: %v", resp.Error)
			return "", resp.Error
		}
		fullResponse.WriteString(resp.Content)
	}

	response := fullResponse.String()
	conversation.Responses = append(conversation.Responses, response)
	log.Printf("Prompt processed successfully for conversation: %s", conversationID)
	return response, nil
}

// ProcessPromptStream processes a prompt and returns a channel for streaming responses
func (s *ChatGPTService) ProcessPromptStream(conversationID string, prompt string) (<-chan StreamResponse, error) {
	log.Printf("Processing prompt stream for conversation: %s", conversationID)
	s.mutex.Lock()
	conversation, ok := s.conversations[conversationID]
	s.mutex.Unlock()
	if !ok {
		log.Printf("Conversation not found, starting new conversation: %s", conversationID)
		s.StartConversation(conversationID, nil)
		conversation = s.conversations[conversationID]
	}

	conversation.PreviousPrompts = append(conversation.PreviousPrompts, conversation.CurrentPrompt)
	conversation.CurrentPrompt = prompt

	log.Printf("Prompt: %s", prompt)

	responseChan, err := s.chatGPTClient.GenerateResponse(prompt, true, conversationID)
	if err != nil {
		return nil, err
	}

	// Directly return the responseChan without additional buffering or delays
	return responseChan, nil
}

// GetConversation retrieves a conversation by its ID
func (s *ChatGPTService) GetConversation(conversationID string) (*Conversation, error) {
	log.Printf("Retrieving conversation: %s", conversationID)
	s.mutex.Lock()
	defer s.mutex.Unlock()

	conversation, ok := s.conversations[conversationID]
	if !ok {
		log.Printf("Conversation not found: %s", conversationID)
		return nil, errors.New("conversation not found")
	}

	log.Printf("Conversation retrieved successfully: %s", conversationID)
	return conversation, nil
}

// ProcessStructuredPrompt handles structured outputs based on the provided JSON schema
func (s *ChatGPTService) ProcessStructuredPrompt(conversationID string, prompt string, schema string, stream bool) (string, error) {
	log.Printf("Processing structured prompt for conversation: %s", conversationID)

	s.mutex.Lock()
	conversation, ok := s.conversations[conversationID]
	s.mutex.Unlock()
	if !ok {
		log.Printf("Conversation not found, starting new conversation: %s", conversationID)
		s.StartConversation(conversationID, nil)
		conversation = s.conversations[conversationID]
	}

	conversation.PreviousPrompts = append(conversation.PreviousPrompts, conversation.CurrentPrompt)
	conversation.CurrentPrompt = prompt

	// Prepare the request body with the structured response format
	requestBody, err := json.Marshal(struct {
		Model          string                 `json:"model"`
		Messages       []map[string]string    `json:"messages"`
		Temperature    float64                `json:"temperature"`
		ResponseFormat map[string]interface{} `json:"response_format"`
		Stream         bool                   `json:"stream"`
	}{
		Model: s.chatGPTClient.model,
		Messages: []map[string]string{
			{
				"role":    "user",
				"content": prompt,
			},
		},
		Temperature: 0.3,
		ResponseFormat: map[string]interface{}{
			"type":        "json_schema",
			"json_schema": json.RawMessage(schema),
			"strict":      true,
		},
		Stream: true,
	})
	if err != nil {
		log.Printf("Failed to marshal request body: %v", err)
		return "", fmt.Errorf("failed to marshal request body: %v", err)
	}

	// Use the modified requestBody in GenerateResponse
	responseChan, err := s.chatGPTClient.GenerateResponse(string(requestBody), stream, conversationID)
	if err != nil {
		log.Printf("Error generating structured response: %v", err)
		return "", err
	}

	var fullResponse strings.Builder
	for resp := range responseChan {
		if resp.Error != nil {
			log.Printf("Error in stream: %v", resp.Error)
			return "", resp.Error
		}
		fullResponse.WriteString(resp.Content)
	}

	response := fullResponse.String()
	conversation.Responses = append(conversation.Responses, response)
	log.Printf("Structured prompt processed successfully for conversation: %s", conversationID)
	return response, nil
}

package chatgpt

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math"
	"math/rand"
	"net/http"
	"sync"
	"time"

	"{{ .serviceName }}/internal/config"

	"golang.org/x/sync/semaphore"
	"golang.org/x/time/rate"
)

// Add retry configuration
const (
	maxRetries = 10
)

type ChatGPTClient struct {
	endpoint  string
	apiKey    string
	client    *http.Client
	model     string
	limiter   *rate.Limiter
	semaphore *semaphore.Weighted
}

type Conversation struct {
	CurrentPrompt   string
	PreviousPrompts []string
	Responses       []string
	Metadata        interface{}
}

type ChatGPTService struct {
	chatGPTClient *ChatGPTClient
	conversations map[string]*Conversation
	mutex         *sync.Mutex
}

func NewChatGPTClient(cfg *config.GPT) (*ChatGPTClient, error) {
	client := &http.Client{}

	// Define the rate limit (e.g., 90 requests per minute)
	limiter := rate.NewLimiter(1.5, 1)

	// Create a semaphore with a weight of 90 to limit to 90 active requests.
	semaphore := semaphore.NewWeighted(90)

	chatGPTClient := &ChatGPTClient{
		endpoint:  cfg.Endpoint,
		apiKey:    cfg.APIKey,
		client:    client,
		model:     cfg.Model,
		limiter:   limiter,
		semaphore: semaphore,
	}
	return chatGPTClient, nil
}

func (c *ChatGPTClient) GenerateResponse(prompt string) (string, error) {
	if err := c.semaphore.Acquire(context.Background(), 1); err != nil {
		return "", err
	}
	defer c.semaphore.Release(1)

	if err := c.limiter.Wait(context.Background()); err != nil {
		return "", fmt.Errorf("rate limiter error: %v", err) // Changed from log.Fatalf to error
	}

	requestBody, err := json.Marshal(struct {
		Model       string              `json:"model"`
		Messages    []map[string]string `json:"messages"`
		Temperature float64             `json:"temperature"`
	}{
		Model:       c.model,
		Messages:    []map[string]string{
				{
					"role": 
					"user", 
					"content": prompt,
				},
			},
		Temperature: 0.3,
	})
	if err != nil {
		return "", fmt.Errorf("failed to marshal request body: %v", err)
	}

	req, err := http.NewRequest(http.MethodPost, c.endpoint, bytes.NewBuffer(requestBody))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("Content-Type", "application/json")

	// fmt.Println("Requesting response from API...")
	// fmt.Printf("Request: %v\n", req)

	var resp *http.Response
	var responseBytes []byte
	for attempt := 0; attempt < maxRetries; attempt++ {
		resp, err = c.client.Do(req)
		if err == nil && resp.StatusCode == http.StatusOK {
			responseBytes, err = io.ReadAll(resp.Body)
			resp.Body.Close()
			if err != nil {
				return "", fmt.Errorf("failed to read response body: %v", err)
			}
			break
		}

		if resp != nil {
			resp.Body.Close()
		}

		// log.Printf("Attempt %d failed: %v. Retrying...\n", attempt+1, err)
		if attempt < maxRetries-1 {
			sleepDuration := time.Second * time.Duration(math.Pow(2, float64(attempt)))
			jitter := time.Duration(rand.Intn(1000)) * time.Millisecond
			time.Sleep(sleepDuration + jitter)
		}
	}

	if err != nil {
		return "", fmt.Errorf("failed to get response from API after %d attempts: %v", maxRetries, err)
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("received non-200 response from API after retries: %d - %s", resp.StatusCode, string(responseBytes))
	}

	var response struct {
		Choices []struct {
			Message struct {
				Role    string `json:"role"`
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}

	err = json.Unmarshal(responseBytes, &response)
	if err != nil {
		return "", fmt.Errorf("failed to unmarshal response: %v", err)
	}

	if len(response.Choices) == 0 {
		return "", fmt.Errorf("no choices in response")
	}

	return response.Choices[0].Message.Content, nil
}

func MustNewChatGPTService(cfg *config.GPT) *ChatGPTService {
	chatGPTClient, err := NewChatGPTClient(cfg)
	if err != nil {
		panic(err)
	}
	return &ChatGPTService{
		chatGPTClient: chatGPTClient,
		conversations: make(map[string]*Conversation),
		mutex:         &sync.Mutex{},
	}
}

func (s *ChatGPTService) StartConversation(conversationID string, metadata interface{}) {
	conversation := &Conversation{
		Metadata: metadata,
	}
	s.mutex.Lock()
	s.conversations[conversationID] = conversation
	s.mutex.Unlock()
}

func (s *ChatGPTService) ProcessPrompt(conversationID string, prompt string) (string, error) {
	s.mutex.Lock()
	conversation, ok := s.conversations[conversationID]
	s.mutex.Unlock()
	if !ok {
		s.StartConversation(conversationID, nil)
		conversation = s.conversations[conversationID]
	}

	conversation.PreviousPrompts = append(conversation.PreviousPrompts, conversation.CurrentPrompt)
	conversation.CurrentPrompt = prompt

	response, err := s.chatGPTClient.GenerateResponse(prompt)

	if err != nil {
		return "", err
	}

	conversation.Responses = append(conversation.Responses, response)
	return response, nil
}

func (s *ChatGPTService) GetConversation(conversationID string) (*Conversation, error) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	conversation, ok := s.conversations[conversationID]
	if !ok {
		return nil, errors.New("conversation not found")
	}

	return conversation, nil
}

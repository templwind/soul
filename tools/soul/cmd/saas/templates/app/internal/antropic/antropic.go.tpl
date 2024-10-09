package anthropic

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

const (
	maxRetries = 10
)

type AnthropicClient struct {
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

type AnthropicService struct {
	anthropicClient *AnthropicClient
	conversations   map[string]*Conversation
	mutex           *sync.Mutex
}

func NewAnthropicClient(cfg *config.Anthropic) (*AnthropicClient, error) {
	client := &http.Client{}

	// Define the rate limit (e.g., 90 requests per minute)
	limiter := rate.NewLimiter(1.5, 1)

	// Create a semaphore with a weight of 90 to limit to 90 active requests.
	semaphore := semaphore.NewWeighted(90)

	anthropicClient := &AnthropicClient{
		endpoint:  cfg.Endpoint,
		apiKey:    cfg.APIKey,
		client:    client,
		model:     cfg.Model,
		limiter:   limiter,
		semaphore: semaphore,
	}
	return anthropicClient, nil
}

func (c *AnthropicClient) GenerateResponse(prompt string) (string, error) {
	if err := c.semaphore.Acquire(context.Background(), 1); err != nil {
		return "", err
	}
	defer c.semaphore.Release(1)

	if err := c.limiter.Wait(context.Background()); err != nil {
		return "", fmt.Errorf("rate limiter error: %v", err)
	}

	requestBody, err := json.Marshal(struct {
		Model       string  `json:"model"`
		Prompt      string  `json:"prompt"`
		MaxTokens   int     `json:"max_tokens_to_sample"`
		Temperature float64 `json:"temperature"`
	}{
		Model:       c.model,
		Prompt:      prompt,
		MaxTokens:   300,
		Temperature: 0.3,
	})
	if err != nil {
		return "", fmt.Errorf("failed to marshal request body: %v", err)
	}

	req, err := http.NewRequest(http.MethodPost, c.endpoint, bytes.NewBuffer(requestBody))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %v", err)
	}

	req.Header.Set("X-API-Key", c.apiKey)
	req.Header.Set("Content-Type", "application/json")

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
		Completion string `json:"completion"`
	}

	err = json.Unmarshal(responseBytes, &response)
	if err != nil {
		return "", fmt.Errorf("failed to unmarshal response: %v", err)
	}

	return response.Completion, nil
}

func MustNewAnthropicService(cfg *config.Anthropic) *AnthropicService {
	anthropicClient, err := NewAnthropicClient(cfg)
	if err != nil {
		panic(err)
	}
	return &AnthropicService{
		anthropicClient: anthropicClient,
		conversations:   make(map[string]*Conversation),
		mutex:           &sync.Mutex{},
	}
}

func (s *AnthropicService) StartConversation(conversationID string, metadata interface{}) {
	conversation := &Conversation{
		Metadata: metadata,
	}
	s.mutex.Lock()
	s.conversations[conversationID] = conversation
	s.mutex.Unlock()
}

func (s *AnthropicService) ProcessPrompt(conversationID string, prompt string) (string, error) {
	s.mutex.Lock()
	conversation, ok := s.conversations[conversationID]
	s.mutex.Unlock()
	if !ok {
		s.StartConversation(conversationID, nil)
		conversation = s.conversations[conversationID]
	}

	conversation.PreviousPrompts = append(conversation.PreviousPrompts, conversation.CurrentPrompt)
	conversation.CurrentPrompt = prompt

	response, err := s.anthropicClient.GenerateResponse(prompt)

	if err != nil {
		return "", err
	}

	conversation.Responses = append(conversation.Responses, response)
	return response, nil
}

func (s *AnthropicService) GetConversation(conversationID string) (*Conversation, error) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	conversation, ok := s.conversations[conversationID]
	if !ok {
		return nil, errors.New("conversation not found")
	}

	return conversation, nil
}

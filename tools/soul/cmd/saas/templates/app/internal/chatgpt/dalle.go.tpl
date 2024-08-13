package chatgpt

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"{{ .serviceName }}/internal/config"
)

// DALLEClient is responsible for communicating with the DALL-E API.
type DALLEClient struct {
	endpoint string
	apiKey   string
	client   *http.Client
	model    string // DALL-E Model
}

// NewDALLEClient creates a new instance of DALLEClient.
func NewDALLEClient(cfg *config.GPT) (*DALLEClient, error) {
	client := &http.Client{}
	dalleClient := &DALLEClient{
		endpoint: cfg.DallEEndpoint,
		apiKey:   cfg.APIKey,
		client:   client,
		model:    cfg.DallEModel,
	}
	return dalleClient, nil
}

func MustNewDALLEClient(cfg *config.GPT) *DALLEClient {
	dalleClient, err := NewDALLEClient(cfg)
	if err != nil {
		panic(err)
	}
	return dalleClient
}

// GenerateImage sends a prompt to the DALL-E API and retrieves the generated image.
func (d *DALLEClient) GenerateImages(prompt string, total int) ([][]byte, error) {
	requestBody, err := json.Marshal(map[string]interface{}{
		"model":   d.model, // Ensure this is set to "dall-e-3" in your configuration
		"prompt":  prompt,
		"n":       total, // Number of images to generate
		"size":    "1024x1024",
		"quality": "standard",
	})
	if err != nil {
		return nil, err
	}

	// fmt.Println("Sending request to DALL-E API...", string(requestBody))

	// Correct the endpoint to match the OpenAI documentation
	req, err := http.NewRequest("POST", d.endpoint, bytes.NewBuffer(requestBody))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+d.apiKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := d.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		responseBody, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("DALL-E API error: %s", string(responseBody))
	}

	responseBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	// Assuming the API returns JSON with URLs or binary data of the generated image
	// Adjust the parsing based on the actual response structure.
	// The example below assumes the API response includes a key for image data or URLs
	var response struct {
		Data []struct {
			ID     string `json:"id"`
			Object string `json:"object"`
			URL    string `json:"url"` // Example: use the URL if the response includes it
			// Include other fields as necessary according to the API response
		} `json:"data"`
	}
	err = json.Unmarshal(responseBytes, &response)
	if err != nil {
		return nil, err
	}

	// This example returns the URL of the first generated image
	// Modify as necessary based on your application's needs
	if len(response.Data) > 0 {
		images := make([][]byte, 0)
		// fmt.Println("Image generated: ", response.Data)
		for _, imageURL := range response.Data {
			// fmt.Println("Image URL: ", imageURL.URL)

			// Now download the image from the URL
			data, err := d.DownloadImage(imageURL.URL)
			if err != nil {
				return nil, fmt.Errorf("downloading image from URL failed: %v", err)
			}
			images = append(images, data)

		}

		return images, nil
	}

	return nil, nil
}

// DownloadImage downloads an image from the given URL and returns the image data as a byte slice.
func (d *DALLEClient) DownloadImage(imageURL string) ([]byte, error) {
	req, err := http.NewRequest("GET", imageURL, nil)
	if err != nil {
		return nil, fmt.Errorf("creating request failed: %v", err)
	}

	// req.Header.Set("Authorization", "Bearer "+d.apiKey) // Set this header if required by the API
	resp, err := d.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("downloading image failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("failed to download image, status code: %d", resp.StatusCode)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("reading response body failed: %v", err)
	}

	return data, nil
}

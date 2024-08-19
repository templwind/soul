package httpx

import (
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
)

type EmailEventRequest struct {
	Email       string `query:"email"`                        // The recipient's email address
	EmailID     string `path:"emailID" optional:"true"`       // Unique identifier for the email
	Event       string `path:"event" optional:"true"`         // Type of event (e.g., open, click)
	URL         string `query:"url" optional:"true"`          // The original URL that was clicked (optional)
	RecipientID string `query:"recipient_id" optional:"true"` // Unique identifier for the recipient
	CampaignID  string `query:"campaign_id" optional:"true"`  // Unique identifier for the email campaign
	TrackingID  string `query:"tracking_id" optional:"true"`  // Unique identifier for tracking this email instance
	LinkID      string `query:"link_id" optional:"true"`      // Identifier for the specific link within the email
	Timestamp   int64  `query:"timestamp" optional:"true"`    // Unix timestamp of the event
	Referrer    string `query:"referrer" optional:"true"`     // The source or context of the email
	UserAgent   string `query:"user_agent" optional:"true"`   // User agent string (optional)
}

func TestEmailEventRequest_Parse(t *testing.T) {
	form := url.Values{}
	// Include the email in the form data or as part of the URL if it should be parsed that way
	form.Add("email", "test@example.com")

	req := httptest.NewRequest("POST", "/track/abc123/open?email=test@example.com&url=https://example.com&recipient_id=recipient-xyz&campaign_id=campaign-abc&tracking_id=track-123&link_id=link-456&timestamp=1627891234&referrer=referrer-info&user_agent=Mozilla/5.0", strings.NewReader(form.Encode()))
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	params := &EmailEventRequest{}

	err := Parse(req, params, "/track/:emailID/:event")
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if params.EmailID != "abc123" {
		t.Errorf("expected emailID to be 'abc123', got '%s'", params.EmailID)
	}

	if params.Event != "open" {
		t.Errorf("expected event to be 'open', got '%s'", params.Event)
	}

	if params.URL != "https://example.com" {
		t.Errorf("expected url to be 'https://example.com', got '%s'", params.URL)
	}

	if params.RecipientID != "recipient-xyz" {
		t.Errorf("expected recipient_id to be 'recipient-xyz', got '%s'", params.RecipientID)
	}

	if params.CampaignID != "campaign-abc" {
		t.Errorf("expected campaign_id to be 'campaign-abc', got '%s'", params.CampaignID)
	}

	if params.TrackingID != "track-123" {
		t.Errorf("expected tracking_id to be 'track-123', got '%s'", params.TrackingID)
	}

	if params.LinkID != "link-456" {
		t.Errorf("expected link_id to be 'link-456', got '%s'", params.LinkID)
	}

	if params.Timestamp != 1627891234 {
		t.Errorf("expected timestamp to be 1627891234, got %d", params.Timestamp)
	}

	if params.Referrer != "referrer-info" {
		t.Errorf("expected referrer to be 'referrer-info', got '%s'", params.Referrer)
	}

	if params.UserAgent != "Mozilla/5.0" {
		t.Errorf("expected user_agent to be 'Mozilla/5.0', got '%s'", params.UserAgent)
	}

	if params.Email != "test@example.com" {
		t.Errorf("expected email to be 'test@example.com', got '%s'", params.Email)
	}
}

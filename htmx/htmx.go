package htmx

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

func IsHtmxRequest(r *http.Request) bool {
	return r.Header.Get("HX-Request") == "true"
}

func IsHtmxBoosted(r *http.Request) bool {
	return r.Header.Get("HX-Boosted") == "true"
}

func IsHtmxHistoryRestoreRequest(r *http.Request) bool {
	return r.Header.Get("HX-History-Restore-Request") == "true"
}

func Redirect(w http.ResponseWriter, r *http.Request, path string) error {
	if path == "" {
		return fmt.Errorf("path cannot be empty")
	}

	if IsHtmxRequest(r) {
		w.Header().Set("HX-Redirect", path)
		w.WriteHeader(http.StatusNoContent)
		return nil
	}

	http.Redirect(w, r, path, http.StatusFound)
	return nil
}

type LocationMap struct {
	Path   string `json:"path"`
	Target string `json:"target"`
}

func Location(w http.ResponseWriter, r *http.Request, target LocationMap) error {
	if IsHtmxRequest(r) {
		data, err := json.Marshal(target)
		if err != nil {
			fmt.Println(err)
			return err
		}
		w.Header().Set("HX-Location", string(data))
		w.WriteHeader(http.StatusNoContent)
		return nil
	}
	http.Redirect(w, r, target.Path, http.StatusFound)
	return nil
}

func Trigger(w http.ResponseWriter, r *http.Request, newTrigger interface{}) error {
	existing := w.Header().Get("HX-Trigger")
	var payloadTriggers map[string]string
	var eventTriggers []string

	if existing != "" {
		if strings.HasPrefix(existing, "{") {
			err := json.Unmarshal([]byte(existing), &payloadTriggers)
			if err != nil {
				return fmt.Errorf("failed to unmarshal existing HX-Trigger header: %v", err)
			}
		} else {
			eventTriggers = append(eventTriggers, splitAndTrim(existing, ",")...)
		}
	} else {
		payloadTriggers = make(map[string]string)
	}

	switch v := newTrigger.(type) {
	case string:
		triggers := splitAndTrim(v, ",")
		eventTriggers = append(eventTriggers, triggers...)
	case map[string]string:
		for key, value := range v {
			payloadTriggers[key] = value
		}
	default:
		return fmt.Errorf("unsupported trigger type: %T", newTrigger)
	}

	var combinedTrigger string
	if len(payloadTriggers) > 0 {
		combinedJSON, err := json.Marshal(payloadTriggers)
		if err != nil {
			return fmt.Errorf("failed to marshal combined HX-Trigger header: %v", err)
		}
		combinedTrigger = string(combinedJSON)
	}

	if len(eventTriggers) > 0 {
		if combinedTrigger != "" {
			combinedTrigger += "," + strings.Join(eventTriggers, ",")
		} else {
			combinedTrigger = strings.Join(eventTriggers, ",")
		}
	}

	w.Header().Set("HX-Trigger", combinedTrigger)
	return nil
}

func PushUrl(w http.ResponseWriter, url string) {
	w.Header().Set("HX-Push-Url", url)
}

func Refresh(w http.ResponseWriter) {
	w.Header().Set("HX-Refresh", "true")
}

func ReplaceUrl(w http.ResponseWriter, url string) {
	w.Header().Set("HX-Replace-Url", url)
}

func Reswap(w http.ResponseWriter, value string) {
	w.Header().Set("HX-Reswap", value)
}

func Retarget(w http.ResponseWriter, selector string) {
	w.Header().Set("HX-Retarget", selector)
}

func Reselect(w http.ResponseWriter, selector string) {
	w.Header().Set("HX-Reselect", selector)
}

func TriggerAfterSettle(w http.ResponseWriter, event string) {
	existing := w.Header().Get("HX-Trigger-After-Settle")
	if existing != "" {
		event = existing + "," + event
	}
	w.Header().Set("HX-Trigger-After-Settle", event)
}

func TriggerAfterSwap(w http.ResponseWriter, event string) {
	existing := w.Header().Get("HX-Trigger-After-Swap")
	if existing != "" {
		event = existing + "," + event
	}
	w.Header().Set("HX-Trigger-After-Swap", event)
}

func splitAndTrim(s, sep string) []string {
	parts := strings.Split(s, sep)
	for i := range parts {
		parts[i] = strings.TrimSpace(parts[i])
	}
	return parts
}

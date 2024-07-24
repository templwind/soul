package update

import (
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

const currentVersion = "v0.0.1"
const repoOwner = "templwind"
const repoName = "soul"

func GetCurrentVersion() string {
	return currentVersion
}

func getLatestRelease() (string, error) {
	url := fmt.Sprintf("https://github.com/%s/%s/releases/latest", repoOwner, repoName)
	resp, err := http.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("failed to fetch latest release: %s", resp.Status)
	}

	// The final URL after redirection contains the version tag
	finalURL := resp.Request.URL.String()
	parts := strings.Split(finalURL, "/")
	if len(parts) < 1 {
		return "", fmt.Errorf("failed to parse version from URL")
	}

	latestVersion := parts[len(parts)-1]
	return latestVersion, nil
}

func UpdateCLI() error {
	cmd := exec.Command("go", "install", fmt.Sprintf("github.com/%s/%s/tools/soul@latest", repoOwner, repoName))
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err := cmd.Run()
	if err != nil {
		return fmt.Errorf("failed to update CLI tool: %w", err)
	}

	return nil
}

func CheckForUpdates() error {
	latestVersion, err := getLatestRelease()
	if err != nil {
		return err
	}

	if strings.Compare(currentVersion, latestVersion) < 0 {
		fmt.Printf("A new version of the CLI tool is available: %s\n", latestVersion)
		fmt.Println("Updating to the latest version...")
		if err := UpdateCLI(); err != nil {
			return fmt.Errorf("failed to update: %w", err)
		}
		fmt.Println("Update successful!")
	} else {
		fmt.Println("You are using the latest version.")
	}

	return nil
}

package k8sutil

import (
	"context"
	"os"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

// IsRunningInKubernetes checks if the application is running inside a Kubernetes cluster
func IsRunningInKubernetes() bool {
	// Check for the presence of the service account token file
	if _, err := os.Stat("/var/run/secrets/kubernetes.io/serviceaccount/token"); err == nil {
		return true
	}
	// Alternatively, check for the KUBERNETES_SERVICE_HOST environment variable
	if os.Getenv("KUBERNETES_SERVICE_HOST") != "" {
		return true
	}
	return false
}

// GetInstanceCount returns the number of pods running with the specified label
// If not running on Kubernetes, it returns 1 for local testing
func GetInstanceCount(appLabel string) (int, error) {
	if !IsRunningInKubernetes() {
		// Not running on Kubernetes, return 1 for local testing
		return 1, nil
	}

	// Create in-cluster config
	config, err := rest.InClusterConfig()
	if err != nil {
		return 0, err
	}

	// Create clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		return 0, err
	}

	// Read the namespace from the service account
	namespaceBytes, err := os.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/namespace")
	if err != nil {
		return 0, err
	}
	namespace := string(namespaceBytes)

	// Get pods in the current namespace with the specified label
	pods, err := clientset.CoreV1().Pods(namespace).List(context.TODO(), metav1.ListOptions{
		LabelSelector: "app=" + appLabel,
	})
	if err != nil {
		return 0, err
	}

	return len(pods.Items), nil
}

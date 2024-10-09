package cmd

import (
	"log"

	"github.com/spf13/cobra"
	"github.com/templwind/soul/tools/soul/internal/update"
)

// UpdateCmd creates the `update` command.
func UpdateCmd() *cobra.Command {
	var cmd = &cobra.Command{
		Use:   "update",
		Short: "Check for and install the latest version of the CLI tool",
		Run: func(cmd *cobra.Command, args []string) {
			if err := update.CheckForUpdates(); err != nil {
				log.Fatalf("Error checking for updates: %v", err)
			}
		},
	}

	return cmd
}

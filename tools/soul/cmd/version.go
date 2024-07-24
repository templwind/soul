package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/templwind/soul/tools/soul/internal/update"
)

// VersionCmd creates the `version` command.
func VersionCmd() *cobra.Command {
	var cmd = &cobra.Command{
		Use:   "version",
		Short: "Print the version number of the CLI tool",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("soul version %s\n", update.GetCurrentVersion())
		},
	}

	return cmd
}

func init() {
	rootCmd.AddCommand(VersionCmd())
}

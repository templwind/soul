package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/templwind/templwind/tools/soul/internal/starter"
)

func LayoutCmd() *cobra.Command {
	var moduleNamespace string

	var cmd = &cobra.Command{
		Use:   "layout [path]",
		Short: "Initialize a new layout",
		Long:  `Setup a new layout with default props`,
		Args:  cobra.ExactArgs(1), // Require exactly one argument for the project path
		Run: func(cmd *cobra.Command, args []string) {
			starter.Execute(args[0], moduleNamespace, "") // Execute initialization with the provided path
		},
	}

	fmt.Println("init.go init() called")
	// Register the flag directly in the command where it's used
	cmd.Flags().StringVarP(&moduleNamespace, "module", "m", "", "Specify the Go module namespace (e.g., github.com/yourusername/projectname)")
	cmd.MarkFlagRequired("module") // Ensuring the module flag is required

	// Adding the init command to the root command in the cmd package
	rootCmd.AddCommand(cmd)

	return cmd
}

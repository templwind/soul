package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/templwind/soul/tools/soul/cmd/echo"
	"github.com/templwind/soul/tools/soul/cmd/parsexo"
	"github.com/templwind/soul/tools/soul/cmd/saas"
)

var rootCmd = &cobra.Command{
	Use:   "soul",
	Short: "soul is a CLI for managing your project",
	Long:  `soul is a Command Line Interface application for setting up and managing your development projects.`,
	// Uncomment the following line if your bare application
	// has an action aassociated with it:
	// Run: func(cmd *cobra.Command, args []string) { },
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	rootCmd.AddCommand(saas.Cmd())
	rootCmd.AddCommand(echo.Cmd())
	rootCmd.AddCommand(parsexo.Cmd())

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %s\n", err)
		os.Exit(1)
	}
}

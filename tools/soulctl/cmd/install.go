package cmd

import (
	"log"

	"github.com/spf13/cobra"
	"github.com/templwind/soul/tools/soulctl/internal/discovery"
	"github.com/templwind/soul/tools/soulctl/internal/installer"
	"github.com/templwind/soul/tools/soulctl/internal/util"
)

func init() {
	// Register the install command and its alias in the cmd package
	rootCmd.AddCommand(newInstallCmd("install", "Installs components, pages, or modules"))
	rootCmd.AddCommand(newInstallCmd("i", "Installs components, pages, or modules (alias for install)"))
}

func newInstallCmd(use, short string) *cobra.Command {
	var projectNamespace string
	var framework string
	var destination string
	var newName string

	var cmd = &cobra.Command{
		Use:   use + " [type] [names...]",
		Short: short,
		Long:  `Installs components, pages, or modules to the specified destination. This command MUST be called within the project directory.`,
		Args:  cobra.MinimumNArgs(1), // Require at least one argument: type
		Run: func(cmd *cobra.Command, args []string) {
			// Read module path from go.mod if projectNamespace is not set
			if projectNamespace == "" {
				modulePath, err := util.GetModuleName(".")
				if err != nil {
					log.Fatalf("Error reading module path from go.mod: %v", err)
				}
				projectNamespace = modulePath
			}

			installType := args[0]
			var names []string
			if len(args) > 1 {
				names = args[1:]
			} else {
				var err error
				names, err = discovery.DiscoverItems(installType)
				if err != nil {
					log.Fatalf("Error discovering %s: %v", installType, err)
				}
			}

			// Validate that destination and newName are provided for pages
			if installType == "page" || installType == "p" {
				if destination == "" || newName == "" {
					log.Fatalf("Error: both destination (-d) and new name (-n) must be provided for installing pages")
				}
			}

			err := installer.Execute(
				installer.WithInstallType(installType),
				installer.WithNameList(names),
				installer.WithProjectNamespace(projectNamespace),
				installer.WithFramework(framework),
				installer.WithDestination(destination),
				installer.WithNewName(newName),
				installer.WithProcessedComponents(make(map[string]bool)),
			)
			if err != nil {
				log.Fatalf("Error installing %s: %v", installType, err)
			}
		},
	}

	// Register the flag directly in the command where it's used
	cmd.Flags().StringVarP(&projectNamespace, "project", "p", "", "Specify the Go project namespace (e.g., github.com/yourusername/projectname)")
	// cmd.MarkFlagRequired("project") // Ensuring the project flag is required

	// Registering the framework flag
	cmd.Flags().StringVarP(&framework, "framework", "f", "echo", "Specify the framework to use (e.g., native, echo, chi, gin)")

	// Registering the destination flag
	cmd.Flags().StringVarP(&destination, "destination", "d", "", "Specify the destination to install the component or page")

	// Registering the new name flag for pages
	cmd.Flags().StringVarP(&newName, "new-name", "n", "", "Specify the new name for the installed page")

	return cmd
}

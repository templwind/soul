package cmd

import (
	"fmt"
	"log"
	"path/filepath"

	"github.com/spf13/cobra"
	"github.com/templwind/templwind/tools/soul/internal/components"
	"github.com/templwind/templwind/tools/soul/internal/installer"
	"github.com/templwind/templwind/tools/soul/internal/starter"
)

func init() {
	// Registering the StarterCmd command
	// rootCmd.AddCommand(StarterCmd())
}

func StarterCmd() *cobra.Command {
	var projectNamespace string
	var framework string

	var cmd = &cobra.Command{
		Use:   "starter [path]",
		Short: "Initialize a new starter project",
		Long:  `Setup a new starter project with default configurations, directory structure, and install necessary dependencies.`,
		Args:  cobra.ExactArgs(1), // Require exactly one argument for the project path
		Run: func(cmd *cobra.Command, args []string) {
			projectPath, err := filepath.Abs(args[0])
			if err != nil {
				fmt.Printf("Error determining full path: %v\n", err)
				return
			}
			// projectPath := args[0]
			starter.Execute(projectPath, projectNamespace, framework) // Execute initialization with the provided path

			// Parse the modules directory looking for components that need to be installed
			modulesDir := filepath.Join(projectPath, "modules")
			foundComponents, err := components.FindComponents(modulesDir)
			if err != nil {
				log.Fatalf("Error finding components: %v", err)
			}

			// Install found components
			fmt.Println("Installing components...")
			fmt.Println("Found components: ", foundComponents)
			fmt.Println("Project namespace: ", projectNamespace)
			fmt.Println("Framework: ", framework)
			fmt.Println("Project path: ", projectPath)
			fmt.Println("Internal UI path: ", filepath.Join(projectPath, "internal/ui"))

			err = installer.Execute(
				installer.WithInstallType("component"),
				installer.WithNameList(foundComponents),
				installer.WithProjectNamespace(projectNamespace),
				installer.WithFramework(framework),
				installer.WithDestination(filepath.Join(projectPath, "internal/ui")),
				installer.WithProcessedComponents(make(map[string]bool)),
			)
			if err != nil {
				log.Fatalf("Error installing components: %v", err)
			}

			// Execute templ generate
			if err := components.RunCmdInProjectDir(projectPath, components.RunTemplGenerate); err != nil {
				log.Fatalf("Error running templ generate: %v", err)
			}

			// Execute go mod tidy
			if err := components.RunCmdInProjectDir(projectPath, components.RunGoModTidy); err != nil {
				log.Fatalf("Error running go mod tidy: %v", err)
			}

			// Execute git init
			if err := components.RunCmdInProjectDir(projectPath, components.RunGitInit); err != nil {
				log.Fatalf("Error running git init: %v", err)
			}
		},
	}

	// Register the flag directly in the command where it's used
	cmd.Flags().StringVarP(&projectNamespace, "project", "p", "", "Specify the Go project namespace (e.g., github.com/yourusername/projectname)")
	cmd.MarkFlagRequired("project") // Ensuring the project flag is required

	// Registering the framework flag
	cmd.Flags().StringVarP(&framework, "framework", "f", "echo", "Specify the framework to use (e.g., native, echo, chi, gin)")

	return cmd
}

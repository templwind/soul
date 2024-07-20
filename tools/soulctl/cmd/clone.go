package cmd

import (
	"log"
	"path/filepath"

	"github.com/spf13/cobra"
	"github.com/templwind/soul/tools/soulctl/internal/components"
	"github.com/templwind/soul/tools/soulctl/internal/installer"
)

func init() {
	// Registering the CloneCmd command
	// rootCmd.AddCommand(CloneCmd())
}

func CloneCmd() *cobra.Command {
	var projectNamespace string
	var framework string
	var starterRepo string

	var cmd = &cobra.Command{
		Use:   "clone [path]",
		Short: "Clone a new starter project",
		Long:  `Clone and setup a new starter project with default configurations, directory structure, and install necessary dependencies.`,
		Args:  cobra.ExactArgs(1), // Require exactly one argument for the project path
		Run: func(cmd *cobra.Command, args []string) {
			projectPath := args[0]

			// Clone the starter repository into RAM
			fs, err := components.CloneRepoToMemory(starterRepo)
			if err != nil {
				log.Fatalf("Error cloning starter repo: %v", err)
			}

			// Process the cloned repository
			err = components.ProcessClonedRepo(fs, projectPath, projectNamespace)
			if err != nil {
				log.Fatalf("Error processing cloned repo: %v", err)
			}

			// Parse the modules directory looking for components that need to be installed
			modulesDir := filepath.Join(projectPath, "modules")
			foundComponents, err := components.FindComponents(modulesDir)
			if err != nil {
				log.Fatalf("Error finding components: %v", err)
			}

			// Install found components
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

	// Registering the starter repository flag
	cmd.Flags().StringVarP(&starterRepo, "repo", "r", "https://github.com/templwind/starters", "Specify the starter repository URL")

	return cmd
}

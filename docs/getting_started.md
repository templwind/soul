# Comprehensive Getting Started with Soul CLI

This guide will walk you through creating, setting up, and running your first SaaS project using Soul CLI.

## Prerequisites

- Ensure you have Soul CLI installed. If not, follow the [installation guide](./installation.md).
- Docker and Docker Compose installed on your system.
- Make utility installed.

## Creating Your First SaaS Project

1. Open your terminal and navigate to the directory where you want to create your project.

2. Run the following command to create a new SaaS project:

   ```
   soul saas -a yourprojectname.api -d .
   ```

   This command tells Soul CLI to create a new SaaS project based on the specifications in `yourprojectname.api` and place it in the current directory.

3. If you don't have an API file yet, create one named `yourprojectname.api`. Here's a simple example:

   ```
   // yourprojectname.api

   type ContactFormRequest {
       Name    string `form:"name"`
       Email   string `form:"email"`
       Message string `form:"message"`
   }

   @server (
       group:      root
       theme:      marketing
       languages:  en
       assetGroup: main
   )
   service YourSaaS {
       @handler home
       @page(
           title: Welcome to YourSaaS
       )
       get /

       @handler contact
       @page(
           title: Contact Us
       )
       get /contact
       post /contact (ContactFormRequest) returns partial
   }
   ```

4. After running the command, Soul CLI will generate the project structure based on your API file.

## Project Structure

A typical Soul CLI project has the following root folders:

- `app`: Contains the main application code
- `db`: Database-related files and migrations
- `temporal`: For handling long-living events

## Understanding the Generated Project

Soul CLI generates a complete project structure, including:

- `app/internal/handler`: Contains handlers for your routes
- `app/internal/logic`: Business logic for your application
- `app/themes`: HTML templates and layouts
- `db/migrations`: Database migration files

Explore the generated files to understand how Soul CLI has structured your project.

## Syncing Your Project with the API File

If you make changes to your .api file, you can sync your project using the following command:

```
make gen
```

This will add any new additions (not subtractions) to the API file and append new handlers to existing files.

## Running Your Project

1. From the root of your project, run:

   ```
   docker compose up
   ```

   This will start your application, database, and any other services defined in your `compose.yaml` file.

2. Open a web browser and go to `http://localhost:8080` (or the port specified in your project).

You should now see your SaaS application running locally!

## Additional Commands

The project comes with a Makefile that provides several useful commands:

- `make templ`: Generate new templates
- `make templ-watch`: Watch templ files and format them
- `make pnpm-build`: Build the frontend
- `make build`: Build the entire project
- `make xo`: Generate models from the database
- `make backup-db`: Backup the SQLite database
- `make restore-db`: Restore the SQLite database from a backup file

## Next Steps

- Customize your generated templates and styles in the `app/themes` directory
- Add more routes and functionality to your API file
- Explore the `app/internal` directory to understand and extend the application logic
- Look into the `temporal` directory if you need to implement long-running processes or workflows
- Explore advanced features like WebSockets and TypeScript client generation

For more detailed information on these topics, check out the respective guides in our documentation.

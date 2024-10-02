## Troubleshooting

If you encounter issues while setting up or running your project, try the following:

1. Ensure all prerequisites are correctly installed and up to date.

2. If you encounter Docker-related issues, try:

```sh
docker compose down --volumes
docker compose up --build
```

3. For database connection issues, check your database configuration in the .env file.

4. If you're seeing compilation errors, ensure you've run `make gen` after making changes to your .api file.

5. For frontend-related issues, try clearing your browser cache or running `make pnpm-build` again.

6. If you're still encountering issues, check our [GitHub Issues](https://github.com/templwind/soul/issues) page or open a new issue for support.

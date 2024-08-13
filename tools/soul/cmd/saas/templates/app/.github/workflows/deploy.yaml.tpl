name: Build and Deploy

on:
  push:
    branches:
      - main

jobs:
  deploy-app:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: 1.22

      - name: Generate Timestamp
        id: timestamp
        run: echo "TIMESTAMP=$(date +'%Y%m%d%H%M')" >> $GITHUB_ENV

      - name: Install doctl
        run: |
          curl -sL https://github.com/digitalocean/doctl/releases/download/v1.98.1/doctl-1.98.1-linux-amd64.tar.gz | tar -xzv
          sudo mv doctl /usr/local/bin

      - name: Authenticate with DigitalOcean Container Registry
        run: doctl registry login --access-token {{ `${{ secrets.DO_ACCESS_TOKEN }}` }}

      - name: Docker Build
        run: make docker-build
        env:
          TARGET: prod
          TIMESTAMP: {{ `${{ env.TIMESTAMP }}` }}

      - name: Docker Push
        run: make docker-push
        env:
          DOCKER_REGISTRY: registry.digitalocean.com/{{.serviceName}}
          DOCKER_REPO: monolith
          DOCKER_TAG: latest
          TIMESTAMP: {{ `${{ env.TIMESTAMP }}` }}

      - name: Deploy to DigitalOcean
        run: |
          # Additional deployment steps
          echo "Deploying to DigitalOcean..."

  
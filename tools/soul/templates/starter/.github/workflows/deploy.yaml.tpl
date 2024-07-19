name: Build and Deploy

on:
  push:
    branches:
      - main

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up Go
        uses: actions/setup-go@v2
        with:
          go-version: 1.22

      - name: Generate Timestamp
        id: timestamp
        run: echo "TIMESTAMP=$(date +'%Y%m%d%H%M')" >> $GITHUB_ENV

      - name: Docker Build
        run: make docker-build
        env:
          TIMESTAMP: ${{ envvar "env.TIMESTAMP" }}

      - name: Docker Push
        run: make docker-push
        env:
          AWS_REGION: ${{ envvar "secrets.AWS_REGION" }}
          AWS_ACCOUNT_ID: ${{ envvar "secrets.AWS_ACCOUNT_ID" }}
          AWS_ECR_REPO: ${{ envvar "secrets.AWS_ECR_REPO" }}
          AWS_ECR_TAG: latest
          AWS_ACCESS_KEY_ID: ${{ envvar "secrets.AWS_ACCESS_KEY_ID" }}
          AWS_SECRET_ACCESS_KEY: ${{ envvar "secrets.AWS_SECRET_ACCESS_KEY" }}
          TIMESTAMP: ${{ envvar "env.TIMESTAMP" }}

      - name: Deploy to AWS
        run: |
          # Additional deployment steps
          echo "Deploying to AWS..."

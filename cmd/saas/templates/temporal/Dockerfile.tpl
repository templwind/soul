# Use an official Golang runtime as a parent image
FROM golang:1.22.3-alpine

# Set the working directory inside the container
WORKDIR /app

# Install dependencies
RUN apk add --no-cache git curl tar

# Download the Temporal CLI binary
RUN curl -L -o temporal.tar.gz "https://temporal.download/cli/archive/latest?platform=linux&arch=amd64"

# Extract the binary
RUN tar -xzf temporal.tar.gz -C /usr/local/bin

# Expose ports
EXPOSE 7233 8233 9090

# Start the Temporal development server with SQLite database
CMD ["sh", "-c", "temporal server start-dev --db-filename ${DB_FILENAME:-/data/temporal.db} --metrics-port 9090 --ui-port 8233 --ip 0.0.0.0"]

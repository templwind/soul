# Use the official Golang image to create a build artifact.
FROM golang:1.22-alpine as dev

# Install necessary dependencies for CGO
RUN apk add -q --update \
    && apk add -q \
            bash \
            git \
            curl \
    && rm -rf /var/cache/apk/*

# Install Air for live reloading and Templ
RUN curl -sSfL https://raw.githubusercontent.com/cosmtrek/air/master/install.sh | sh -s -- -b $(go env GOPATH)/bin

# Configure Git
# using a private repo? 
# Uncomment the following command to configure git credentials using a personal access token
# https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
# RUN git config --global url."https://<git-username>:ghp_<git-token>@github.com".insteadOf "https://github.com"

# Install Templ
RUN go install github.com/a-h/templ/cmd/templ@latest

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy everything from the current directory to the Working Directory inside the container
COPY . .

RUN make templ-generate
# RUN make css

# Build the Go app
RUN CGO_ENABLED=0 go build -o /go/bin/app

CMD ["air"]

# Start a new stage from scratch
FROM gcr.io/distroless/static-debian11 as prod

# Copy the binary to the production image from the builder stage.
COPY --from=dev /go/bin/app /

# Run the binary program produced by `go build`
CMD ["/app"]

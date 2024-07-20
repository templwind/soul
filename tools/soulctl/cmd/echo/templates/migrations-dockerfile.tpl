# Stage 1: Determine the architecture
FROM debian:bullseye-slim AS arch
RUN dpkg --print-architecture | grep -q 'amd64' && echo "x86_64" > /arch.txt || echo "arm64" > /arch.txt

# Stage 2: Build the final image
FROM alpine:latest

# Install required packages
RUN apk add --no-cache wget sqlite

# Copy the architecture from the first stage
COPY --from=arch /arch.txt /arch.txt

# Use the architecture to download the correct binary
ARG GOOSE_VERSION=v3.11.0
RUN ARCH=$(cat /arch.txt) && \
    GOOSE_BINARY_URL=https://github.com/pressly/goose/releases/download/${GOOSE_VERSION}/goose_linux_${ARCH} && \
    wget -O /bin/goose ${GOOSE_BINARY_URL} && \
    chmod 755 /bin/goose

COPY ./run-migrations.sh /run-migrations.sh
RUN chmod +x /run-migrations.sh
COPY ./migrations/ ./migrations/

# Add healthcheck script
COPY ./healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh

ENV PATH="/bin:/sbin:${PATH}"

CMD ["/bin/sh", "-c", "/run-migrations.sh"]

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s CMD /healthcheck.sh

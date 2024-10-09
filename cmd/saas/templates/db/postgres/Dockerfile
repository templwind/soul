# Stage 1: Determine the architecture
FROM debian:bullseye-slim AS arch
RUN dpkg --print-architecture | grep -q 'amd64' && echo "x86_64" > /arch.txt || echo "arm64" > /arch.txt

# Stage 2: Build the final image
FROM governmentpaas/psql:latest

# Copy the architecture from the first stage
COPY --from=arch /arch.txt /arch.txt

# Use the architecture to download the correct binary
ARG GOOSE_VERSION=v3.21.1
RUN ARCH=$(cat /arch.txt) && \
    GOOSE_BINARY_URL=https://github.com/pressly/goose/releases/download/${GOOSE_VERSION}/goose_linux_${ARCH} && \
    wget -O /bin/goose ${GOOSE_BINARY_URL} && \
    chmod 755 /bin/goose

COPY ./wait-for-postgres.sh /
COPY ./run-migrations.sh /
COPY ./migrations/ ./migrations/

RUN chmod +x /wait-for-postgres.sh /run-migrations.sh

ENV PATH="/bin:/sbin:${PATH}"

CMD /bin/sh -c "/wait-for-postgres.sh && /run-migrations.sh"

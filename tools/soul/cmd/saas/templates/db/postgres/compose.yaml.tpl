version: "3"
services:
  # ###############################
  # ## DB                        ##
  # ###############################
  postgres:
    image: postgres:16
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_HOST: ${POSTGRES_HOST}
      POSTGRES_PORT: ${POSTGRES_PORT}
      DSN: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}?connect_timeout=180&sslmode=${POSTGRES_SSL_MODE}
      DEV_POSTGRES_DSN: postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_DEV_HOST}:${POSTGRES_DEV_PORT}/${POSTGRES_DB}?connect_timeout=180&sslmode=${POSTGRES_SSL_MODE}
    restart: unless-stopped
    volumes:
      - .db:/var/lib/postgresql/data
    healthcheck:
      test:
        ["CMD", "pg_isready", "-h", "localhost", "-p", "5432", "-U", "postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - {{ .serviceName }}

  # ###############################
  # ## Migrations                ##
  # ###############################
  migrations:
    build:
      context: .
    depends_on:
      - postgres
    volumes:
      - ./wait-for-postgres.sh:/wait-for-postgres.sh
      - ./run-migrations.sh:/run-migrations.sh
      - ./migrations:/migrations
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_HOST: ${POSTGRES_HOST}
      POSTGRES_PORT: ${POSTGRES_PORT}
      DSN: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}?connect_timeout=180&sslmode=${POSTGRES_SSL_MODE}
      DEV_POSTGRES_DSN: postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_DEV_HOST}:${POSTGRES_DEV_PORT}/${POSTGRES_DB}?connect_timeout=180&sslmode=${POSTGRES_SSL_MODE}
    command: ["/run-migrations.sh"]
    networks:
      - {{ .serviceName }}

networks:
  {{ .serviceName }}:
    driver: bridge

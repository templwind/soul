services:
  {{ if not .isService -}}
  {{- if eq .dbType "postgres" }}
  # ###############################
  # ## DB                        ##
  # ###############################
  postgres:
    image: postgres:16
    ports:
      - "5432:5432"
    env_file:
      - .env
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
      - {{.serviceName}}
  {{- end }}

  # ###############################
  # ## Migrations                ##
  # ###############################
  migrations:
    {{- if eq .dbType "postgres" }}
    depends_on:
      - postgres
    {{- end }}
    build:
      context: ./db
    volumes:
      {{- if eq .dbType "postgres" }}
      - ./db/wait-for-postgres.sh:/wait-for-postgres.sh
      {{- end }}
      - ./db/run-migrations.sh:/run-migrations.sh
      - ./db/migrations:/migrations
      - ./db/data:/data
    env_file:
      - .env
    environment:
      - DB_FILE=/data/{{.dsnName}}.db
    command: ["/run-migrations.sh"]
    healthcheck:
      test: ["CMD", "/healthcheck.sh"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 5s
    networks:
      - {{.serviceName}}


  # ###############################
  # ## Temporal                  ##
  # ###############################
  temporal:
    logging:
      driver: "none"
    env_file:
      - .env
    depends_on:
      - postgres
    environment:
      - DB=postgres12
      - DB_PORT=${POSTGRES_PORT}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PWD=${POSTGRES_PASSWORD}
      - POSTGRES_SEEDS=${POSTGRES_HOST}
      - DYNAMIC_CONFIG_FILE_PATH=config/dynamicconfig/development-sql.yaml
    image: temporalio/auto-setup:${TEMPORAL_VERSION}
    ports:
      - 7233:7233
    volumes:
      - ./temporal/dynamicconfig:/etc/temporal/config/dynamicconfig
    networks:
      - {{.serviceName}}

  temporal-admin-tools:
    logging:
      driver: "none"
    env_file:
      - .env
    depends_on:
      - temporal
    environment:
      - TEMPORAL_ADDRESS=temporal:7233
      - TEMPORAL_CLI_ADDRESS=temporal:7233
    image: temporalio/admin-tools:${TEMPORAL_ADMINTOOLS_VERSION}
    stdin_open: true
    tty: true
    networks:
      - {{.serviceName}}

  temporal-ui:
    logging:
      driver: "none"
    env_file:
      - .env
    depends_on:
      - temporal
    environment:
      - TEMPORAL_ADDRESS=temporal:7233
      - TEMPORAL_CORS_ORIGINS=http://localhost:3000
    image: temporalio/ui:${TEMPORAL_UI_VERSION}
    ports:
      - 8080:8080
    networks:
      - {{.serviceName}}
  {{- end }}
  # ###############################
  # ## App                       ##
  # ###############################
  {{.serviceName}}:
    build: 
      context: ./{{.serviceName}}
      target: dev
    depends_on:
      - migrations
      - temporal
    ports:
      - 8888:8888
    env_file:
      - .env
    {{- if eq .dbType "postgres" }}
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_HOST: ${POSTGRES_HOST}
      POSTGRES_PORT: ${POSTGRES_PORT}
      DSN: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}?connect_timeout=180&sslmode=${POSTGRES_SSL_MODE}
      DEV_POSTGRES_DSN: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_DEV_HOST}:${POSTGRES_DEV_PORT}/${POSTGRES_DB}?connect_timeout=180&sslmode=${POSTGRES_SSL_MODE}
      GO_ENV: production
    {{- end}}
    privileged: true
    volumes:
      - ./{{.serviceName}}:/app
    restart: always
    logging:
      driver: "json-file"
      options:
        max-size: "10m" # Maximum size of the log file before it gets rotated
        max-file: "3"   # Maximum number of log files to keep
    networks:
      - {{.serviceName}}


networks:
  {{.serviceName}}:
    driver: bridge

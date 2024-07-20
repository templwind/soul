services:
  # ###############################
  # ## App                       ##
  # ###############################
  app:
    build: 
      context: .
      target: dev
    depends_on:
      - migrations
      - temporal
    ports:
      - 8888:8888
    env_file:
      - .env
    environment:
      - GO_ENV=production
    privileged: true
    volumes:
      - ./:/app
      - ./db:/db
      - ./uploads:/uploads
    restart: always
    logging:
      driver: "json-file"
      options:
        max-size: "10m" # Maximum size of the log file before it gets rotated
        max-file: "3"   # Maximum number of log files to keep
    networks:
      - {{.serviceName}}

  # ###############################
  # ## Temporal                  ##
  # ###############################
  temporal:
    build:
      context: ./temporal
      dockerfile: Dockerfile
    ports:
      - "7233:7233" # Temporal frontend gRPC service
      - "8233:8233" # Temporal Web UI
      - "9090:9090" # Metrics
    volumes:
      - ./temporal/data:/data
    environment:
      - DB_FILENAME=/data/temporal.db
    networks:
      - {{.serviceName}}

  # ###############################
  # ## Migrations                ##
  # ###############################
  migrations:
    build:
      context: ./db
    volumes:
      - ./db/migrations:/migrations
      - ./db/data:/data
    environment:
      - DB_FILE=/data/{{.dsnName}}.db
    networks:
      - apollo
    command: ["/run-migrations.sh"]
    healthcheck:
      test: ["CMD", "/healthcheck.sh"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 5s

networks:
  {{.serviceName}}:
    driver: bridge

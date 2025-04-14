services:
  # ###############################
  # ## DB                        ##
  # ###############################
  postgres:
    image: postgres:16
    ports:
      - "5432:5432"
    env_file:
      - .env
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

  # ###############################
  # ## App                       ##
  # ###############################
  {{.serviceName}}:
    build: 
      context: ./{{.serviceName}}
      target: dev
    depends_on:
      - migrations
    ports:
      - 8888:8888
    env_file:
      - .env
    privileged: true
    volumes:
      - ./{{.serviceName}}:/app
    restart: always
    networks:
      - {{.serviceName}}

networks:
  {{.serviceName}}:
    driver: bridge

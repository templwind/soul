version: "3"
services:
  migrations:
    build: .
    volumes:
      - ./migrations:/migrations
      - ./data:/data
    environment:
      - DB_FILE=/data/{{.dsnName}}.db
    command: ["/run-migrations.sh"]
    networks:
      - {{.serviceName}}

networks:
  {{.serviceName}}:
    driver: bridge

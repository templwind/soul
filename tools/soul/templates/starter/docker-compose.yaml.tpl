services:
  {{ .AppName }}:
    build: 
      context: .
      target: dev
    ports:
      - 8888:8888
    env_file:
      - .env
    privileged: true
    volumes:
      - .:/app
    restart: always
    networks:
      - {{ .AppName }}

networks:
  {{ .AppName }}:
    driver: bridge

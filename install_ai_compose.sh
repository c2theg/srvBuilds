#----------------------------------------------------
# Version 0.0.16
# Updated: 1/31/2026
#
# To Stop and remove all:
#  docker compose down
#----------------------------------------------------
services:
  ollama:
    container_name: "ollama"
    image: ollama/ollama:latest
    restart: always
    ports:
      - "11434:11434"  # Exposes API for automation tasks
    volumes:
      - /usr/share/ollama/models:/root/.ollama/models
    environment:
      - OLLAMA_HOST=0.0.0.0 # Allows external API access
    # ADD THIS: Tells Docker how to know Ollama is "Ready"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 5s
      timeout: 5s
      retries: 5



  open-webui:
    container_name: "ollama_openwebui"
    image: ghcr.io/open-webui/open-webui:main
    restart: always
    ports:
      - "3000:8080"
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
    volumes:
      - open-webui-data:/app/backend/data
    depends_on:
      - ollama

volumes:
  open-webui-data:

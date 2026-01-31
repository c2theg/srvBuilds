#----------------------------------------------------
# Version 0.0.14
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

  # This helper container pulls the model once, then exits
  ollama-pull-model:
    container_name: "ollama_model_downloader"
    image: ollama/ollama:latest
    volumes:
      - /usr/share/ollama/models:/root/.ollama/models
    entrypoint: /bin/sh
    command: >
      -c "sleep 5; ollama pull minimax-m2.1:cloud"
      -c "sleep 5; ollama pull ministral-3:8b"
      -c "sleep 5; ollama pull llama3.2:3b"
      -c "sleep 5; ollama pull qwen3-vl:8b"
      -c "sleep 5; ollama pull qwen3-embedding:0.6b"
    depends_on:
      - ollama

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

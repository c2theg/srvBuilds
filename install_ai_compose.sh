#----------------------------------------------------
# Version 0.0.12
# Updated: 1/31/2026
#----------------------------------------------------
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: always
    ports:
      - "11434:11434"  # Exposes API for automation tasks
    volumes:
      - /usr/share/ollama/models:/root/.ollama/models
    environment:
      - OLLAMA_HOST=0.0.0.0 # Allows external API access

  # This helper container pulls the model once, then exits
  ollama-pull-model:
    image: ollama/ollama:latest
    container_name: ollama-pull-model
    volumes:
      - /usr/share/ollama/models:/root/.ollama/models
    entrypoint: /bin/sh
    command: >
      -c "sleep 5; ollama pull minimax-m2.1:cloud"
      -c "sleep 5; ollama pull ministral-3:8b"
      -c "sleep 5; ollama pull llama3.2:3b"
      -c "sleep 5; ollama pull qwen3-vl:8b"
    depends_on:
      - ollama

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
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

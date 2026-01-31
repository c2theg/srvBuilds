#!/bin/bash
#  Updated: 1/31/2026
#  Version: 0.0.2
#-------------------------

echo "Checking if Ollama is ready..."
until $(curl --output /dev/null --silent --head --fail http://localhost:11434); do
    printf '.'
    sleep 2
done

echo -e "\nOllama is up! Pulling models..."

# List the models you want to install here
MODELS=("llama3.2:latest,minimax-m2.1:cloud,qwen3-embedding:0.6b,ministral-3:8b,qwen3-vl:8b")

for MODEL in "${MODELS[@]}"; do
    echo "Downloading $MODEL..."
    docker exec -it ollama ollama pull $MODEL
done

echo "Setup complete! Models are stored in /usr/share/ollama/models"

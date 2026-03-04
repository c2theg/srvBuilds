#!/bin/bash
#  Updated: 3/4/2026
#  Version: 0.0.20
#  Purpose:  Downloads a list of LLM Models into Ollama hosted locally in a docker container
#  Install:  wget -O "install_ai_models.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_models.sh && chmod +x install_ai_models.sh && ./install_ai_models.sh
#
#---------------------------------------------
wget -O "install_ai_models.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_models.sh && chmod +x install_ai_models.sh

# Create the directory (Just incase its not present)
sudo mkdir -p /usr/share/ollama/models
# Give the directory appropriate permissions for the Docker container
sudo chmod -R 777 /usr/share/ollama/models


echo "Checking if Ollama is ready..."
until $(curl --output /dev/null --silent --head --fail http://localhost:11434); do
    printf '.'
    sleep 2
done

echo -e "\nOllama is up! \n\n\n"


echo -e "\nUpdate all models\n"
ollama list | tail -n +2 | awk '{print $1}' | xargs -I {} ollama pull {}
echo -e "\nAll models updated\n"


#-----------------------------------------------------------------------------------------
# AI Models
#-----------------------------------------------------------------------------------------


echo "

Downloading AI Models...

"
MODELS=("llama3.2:latest" "minimax-m2.1:cloud" "qwen3-embedding:0.6b" "ministral-3:8b" "qwen3-vl:8b")

for MODEL in "${MODELS[@]}"; do
    echo "
    ------------------------------------------
    "
    echo "Downloading $MODEL..."
    #docker exec -it ollama ollama pull $MODEL
    ollama pull $MODEL
done

echo "

------------------------------------------

"

echo "

Downloading Enhanced AIModels...

"
MODELS=("qwen3:14b-q4_K_M" "mistral-small3.2:24b-instruct-2506-q4_K_M" "llama3.2:3b-instruct-q8_0" "gemma3:4b" "qwen2.5vl:7b" "qwen3-embedding:4b")

for MODEL in "${MODELS[@]}"; do
    echo "
    ------------------------------------------
    "
    echo "Downloading $MODEL..."
    #docker exec -it ollama ollama pull $MODEL
    ollama pull $MODEL
done

echo "

------------------------------------------


Setup complete! Models are stored in /usr/share/ollama/models

All models installed successfully!

You can now select them in Open WebUI at http://localhost:3000


"

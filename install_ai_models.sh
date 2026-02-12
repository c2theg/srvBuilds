#!/bin/bash
#  Updated: 2/11/2026
#  Version: 0.0.10
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



#-- Image Generation ---
#ollama pull llama3.2-vision

# echo "

# Downloading Gemma...  https://ollama.com/library/gemma3

# "
# ollama pull gemma3:4b
#ollama pull codegemma:7b

#------------------------------------------------------------
#ollama run tinyllama         # 1.1b
#ollama run nemotron-mini     # 4b - Nvidia
#ollama pull nemotron-3-nano:30b-cloud

#ollama run llama3-chatqa     # 8b - Nvidia - ChatQA
#ollama run granite3-dense:8b # 8b - IBM RAG

#----------------- Vision Processing -----------------
# ollama pull qwen3-vl:latest

# echo "

# Downloading llava:7b...

# "
#ollama pull llava:7b
#ollama pull llava-llama3
#----------------- Text Processing -----------------

#--- RAG Models ---
# ollama pull command-r:35b
# ollama pull command-r7b

 #- EMBEDDINGS (RAG) -
# echo "

# Downloading Embeddings...

# "

# https://ollama.com/library/qwen3-embedding

#ollama pull qwen3-embedding:4b
#ollama pull nomic-embed-text
#ollama pull mxbai-embed-large
#ollama pull snowflake-arctic-embed


#-- Coding / Natural Language / Agentic tasks ---
# ollama pull deepseek-r1:latest
# ollama pull qwen3-coder:latest
# ollama pull deepseek-coder:1.3b

# Qwen-8B (Alibaba Cloud)
# ollama pull qwen3:latest 

#--- OpenAI ---
# ollama pull gpt-oss:latest
# ollama pull gpt-oss:20b


#--- Security (Prompt) ----
# echo "

# Downloading llama-guard3t...

# "
#ollama pull llama-guard3:latest  # 8b - Meta
#ollama run shieldgemma:latest   # 9b - Google

#---- Stable Difusion ----
# https://github.com/AUTOMATIC1111/stable-diffusion-webui
#sudo add-apt-repository ppa:deadsnakes/ppa
#sudo apt update
#sudo apt install python3.11

# Manjaro/Arch
#sudo pacman -S yay
#yay -S python311 # do not confuse with python3.11 package

# Only for 3.11
# Then set up env variable in launch script
#export python_cmd="python3.11"
# or in webui-user.sh
#python_cmd="python3.11"

#-- install 
#wget -q https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/webui.sh && chmod u+x webui.sh && ./webui.sh
#---- end stable difusion ----

echo "

Downloading New Models...

"
MODELS=("llama3.2:latest" "minimax-m2.1:cloud" "qwen3-embedding:0.6b" "ministral-3:8b" "qwen3-vl:8b")

for MODEL in "${MODELS[@]}"; do
    echo "
    ------------------------------------------
    "
    echo "Downloading $MODEL..."
    docker exec -it ollama ollama pull $MODEL
done

echo "

------------------------------------------

Setup complete! Models are stored in /usr/share/ollama/models

All models installed successfully!

You can now select them in Open WebUI at http://localhost:3000


"

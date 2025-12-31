#!/bin/sh
#
clear
echo "


 _____             _         _    _          _
|     |___ ___ ___| |_ ___ _| |  | |_ _ _   |_|
|   --|  _| -_| .'|  _| -_| . |  | . | | |   _
|_____|_| |___|__,|_| |___|___|  |___|_  |  |_|
                                     |___|

 _____ _       _     _           _              _____    __    _____
|     | |_ ___|_|___| |_ ___ ___| |_ ___ ___   |     |__|  |  |   __|___ ___ _ _
|   --|   |  _| |_ -|  _| . | . |   | -_|  _|  | | | |  |  |  |  |  |  _| .'| | |
|_____|_|_|_| |_|___|_| |___|  _|_|_|___|_|    |_|_|_|_____|  |_____|_| |__,|_  |
                            |_|                                             |___|


Version:  0.0.60
Last Updated:  12/31/2025

# https://ollama.com/search


Install:
    rm install_ai.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai.sh && chmod u+x install_ai.sh


Recommended (after):
    rm update_ai_models.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_ai_models.sh && chmod u+x update_ai_models.sh

"

# linux-modules-nvidia-580-open-generic-hwe-24.04

#-- update yourself! --
rm install_ai.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai.sh && chmod u+x install_ai.sh
sudo apt update
sudo apt install -y --no-install-recommends wget curl gnupg2 git python3 python3-venv libgl1 libglib2.0-0


if [ ! -f "install_docker.sh" ]; then
     echo " You need docker first before running this. This will download a docker installer and run it for you. "
     wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_docker.sh
     chmod u+x install_docker.sh
     ./install_docker.sh
fi


#rm install_python3.sh
wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_python3.sh && chmod u+x install_python3.sh
#./install_python3.sh

#--------------------------------------------------------------------------------------------
# Docker - Ollama
# docker pull ollama/ollama

# Install & Update Ollama to latest version using:
if [ ! -f "ollama_install.sh" ]; then
    #curl -fsSL https://ollama.com/install.sh | sh
    wget -O ollama_install.sh  https://ollama.com/install.sh && chmod u+x ollama_install.sh && ./ollama_install.sh
fi

ollama --version


echo "

grep MemTotal /proc/meminfo

Downloading and Installing AMD GPU / AMD Ryzen AI 9 HX PRO 370 - Drivers...

dmesg | grep -e IOMMU -e AMD-Vi


"

sudo apt install -y jq
sudo apt install -y linux-oem-24.04b
# sudo apt install -y fdutils linux-oem-6.14-tools

lspci -k | grep -EA3 'VGA|3D|Display'
lspci | grep VGA

GPU_INFO=$(lspci -k | grep -EA3 'VGA|3D|Display')

if echo "$GPU_INFO" | grep -qi "nvidia"; then
    echo "NVIDIA GPU detected."    
    echo "
 
     ---- Installing Nvidia CUDA Drivers ----
    
    find nvidia devices:
    
        lspci | grep -i nvidia
        lspci -nn | grep -i nvidia

        
    https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=24.04&target_type=deb_local


    "

    #--- Ubuntu 22.04 ---
    #Nvidia CUDA - https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_local
    #wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
    #sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
    #wget https://developer.download.nvidia.com/compute/cuda/12.6.3/local_installers/cuda-repo-ubuntu2204-12-6-local_12.6.3-560.35.05-1_amd64.deb
    #sudo dpkg -i cuda-repo-ubuntu2204-12-6-local_12.6.3-560.35.05-1_amd64.deb
    #sudo cp /var/cuda-repo-ubuntu2204-12-6-local/cuda-*-keyring.gpg /usr/share/keyrings/
    
    #--- Ubuntu 24.04 ---
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-ubuntu2404.pin
    sudo mv cuda-ubuntu2404.pin /etc/apt/preferences.d/cuda-repository-pin-600
    wget https://developer.download.nvidia.com/compute/cuda/13.1.0/local_installers/cuda-repo-ubuntu2404-13-1-local_13.1.0-590.44.01-1_amd64.deb
    sudo dpkg -i cuda-repo-ubuntu2404-13-1-local_13.1.0-590.44.01-1_amd64.deb
    sudo cp /var/cuda-repo-ubuntu2404-13-1-local/cuda-*-keyring.gpg /usr/share/keyrings/
    sudo apt-get update
    sudo apt-get -y install cuda-toolkit-13-1

    #------------------------------
    sudo apt-get update
    sudo apt-get -y install cuda-toolkit-12-6
    sudo apt-get install -y nvidia-open

   
elif echo "$GPU_INFO" | grep -qi "amd"; then
    echo "AMD GPU detected."
    
    
    curl -L https://ollama.com/download/ollama-linux-amd64-rocm.tgz -o ollama-linux-amd64-rocm.tgz
    sudo tar -C /usr -xzf ollama-linux-amd64-rocm.tgz
    
    sudo apt install -y libdrm-amdgpu1 libhsa-runtime64-1 libhsakmt1 rocminfo
    
    rm ollama-linux-amd64-rocm.tgz


    echo "
    
    Add to grup:
      nano /etc/default/grub  (remove back slashes)
          GRUB_CMDLINE_LINUX_DEFAULT=\"amd_iommu=on iommu=pt\"
    
      save and close
      update-grub
    
    
    On HOST (Proxmox) 
    issue:
        lspci -nn | grep -i amd
    look for:
       00:00.2 IOMMU [0806]: Advanced Micro Devices, Inc. [AMD] Strix/Strix Halo IOMMU [1022:1508]
       
    Verify correct function with:  rocminfo
    
    "
else
    echo "No NVIDIA or AMD GPU found in relevant PCI slots."
    # echo "Installing ARM64 (Apple Mac, Pi, etc.)... \r\n "
    # curl -L https://ollama.com/download/ollama-linux-arm64.tgz -o ollama-linux-arm64.tgz
    # sudo tar -C /usr -xzf ollama-linux-arm64.tgz
fi

#---- AI MODELS ----
# https://ollama.com/search

ollama list
echo "

"

echo "

Downloading llama3.2:latest ...

"
#-- Image Generation ---
ollama pull llama3.2:latest     # 3b    - Meta
#ollama pull llama3.2-vision

echo "

Downloading Gemma...  https://ollama.com/library/gemma3

"
ollama pull gemma3:4b
#ollama pull codegemma:7b


echo "

Downloading Mistral-3... (https://ollama.com/library/ministral-3) 

"
ollama pull ministral-3:latest
#ollama pull mistral:7b
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
ollama pull qwen3-embedding:0.6b
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
# Debian-based:
#sudo apt install -y wget git python3 python3-venv libgl1 libglib2.0-0

ollama list

# Ubuntu 24.04
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.11

# Manjaro/Arch
#sudo pacman -S yay
#yay -S python311 # do not confuse with python3.11 package

# Only for 3.11
# Then set up env variable in launch script
export python_cmd="python3.11"
# or in webui-user.sh
python_cmd="python3.11"

#-- install 
wget -q https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/webui.sh && chmod u+x webui.sh && ./webui.sh

#-------------------
echo "


"
#apt install python3.12-venv
#apt install python3-venv
#python3 -m venv DevEnv1 && source DevEnv1/bin/activate
#python3 -m venv DevEnv1 && source ~/bin/activate
#--------------------------------
wait
source /opt/python_shared/bin/activate
#source ~/.bashrc
#activate-shared
wait
echo "


--- Installing Python Pip3 ---
   Python global venv:   /opt/python_shared/bin/activate


"
pip3 install requests urllib3 beautifulsoup4 pymongo

pip3 install ollama
pip3 install pdfplumber
pip3 install langchain langchain-core langchain-ollama langchain-community langchain_text_splitters
pip3 install unstructured unstructured[all-docs]
pip3 install fastembed
pip3 install sentence-transformers
pip3 install elevenlabs
#--- Vector Databases ---
# Milvus lite (10k - 100k vectors)
#pip3 install milvus
# Milvus Standalone (single machine (1M - 10M Vectors) / Milvus-cluster (10B vectors)
pip3 install -U pymilvus
#in memory vector database, single node
pip3 install chromadb
#------- Install Data Science libs -------
pip3 install matplotlib
pip3 install numpy
pip3 install pandas
pip3 install scipy
python -m pip install "dask[complete]"

#- visuals -
pip3 install bokeh # https://bokeh.org/
pip3 install seaborn # https://seaborn.pydata.org/installing.html
pip3 install plotly # https://plotly.com/python/getting-started/

# install NLP Libraries
pip3 install textblob nltk spacy wordcloud

# Machine Learning
pip3 install scikit-learn joblib

# Core email processing
pip install html2text 

# For Transformer models (GPU recommended)
pip install torch transformers datasets

# Download NLTK data
python -m nltk.downloader punkt stopwords wordnet averaged_perceptron_tagger

# Download spaCy model
python -m spacy download en_core_web_sm

#------- Install Machine Learning libs -------
pip3 install torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip3 install tensorflow
pip3 install scikit-learn
pip3 install torchvision

#pip3 install catboost
# LightGBM -> https://lightgbm.readthedocs.io/en/stable/Installation-Guide.html
pip3 install keras # Yolo3 requirement
#pip3 install gym  # -> https://github.com/openai/gym
#pip3 install xgboost # -> https://xgboost.readthedocs.io/en/stable/install.html


#------- Generative AI -------
pip3 install dalle2-pytorch # -> https://github.com/lucidrains/DALLE2-pytorch
pip3 install pyro-ppl # -> https://pyro.ai/examples/intro_long.html
#pip3 install glm_saga # -> https://pytorch.org/blog/empowering-models-performance/
# pip install imageai --upgrade   |  ImageAI #-> https://imageai.readthedocs.io/en/latest/#:~:text=ImageAI%20is%20a%20python%20library,and%20few%20lines%20of%20code.
# StyleGen #-> https://github.com/NVlabs/stylegan2
#pip3 install flax # -> https://flax.readthedocs.io/en/latest/
#pip3 install -U jax # -> Many Install options depending on hardware -> https://github.com/jax-ml/jax
# NeRF -> https://github.com/bmild/nerf

#------- Computer Vision / Real-Time Object Detection -------
pip3 install opencv-python # https://docs.opencv.org/4.x/d6/d00/tutorial_py_root.html
# Darknet # https://github.com/mdv3101/darknet-yolov3 |  https://pjreddie.com/darknet/
# pip3 install YOLOv3 # -> https://pjreddie.com/darknet/yolo/ | https://viso.ai/deep-learning/yolov3-overview/
# pip3 install yolo-v4 #-> https://github.com/philipperemy/python-darknet-yolo-v4

#- https://huggingface.co/datasets?task_categories=task_categories%3Aimage-to-text
# google/imageinwords  # https://huggingface.co/datasets/google/imageinwords

#-----------------------------
ollama list
ollama --version

#-- update all models --
ollama list | tail -n +2 | awk '{print $1}' | xargs -I {} ollama pull {}
echo "


---- List all Models ----


"

curl http://localhost:11434/api/tags | jq .

echo "

------------------------------
Hello World - Ollama! 
------------------------------

"

# llama3.2
# llama3.2-vision
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Why is the sky blue?",
  "stream": false
}'

# curl http://localhost:11434/api/generate -d '{
#   "model": "llama3.2-vision",
#   "prompt": "Generate me a picture of a beautifly sunset and save the picture locally",
#   "stream": false
# }'

echo "


"
#---- LLAMA Web UI --- https://github.com/open-webui/open-webui#troubleshooting

if echo "$GPU_INFO" | grep -qi "nvidia"; then
    echo "NVIDIA GPU detected."
    
    #-- GPU (Nvidia) & CPU --
    # You need - nvidia-container-toolkit
    #  https://github.com/NVIDIA/nvidia-container-toolkit
    #  https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list


    export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.18.0-1
      sudo apt-get install -y \
          nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
          nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
          libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
          libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}

    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
    #docker run -d -p 3000:8080 --gpus=all -v ollama:/root/.ollama -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:ollama

    #-- Nvidia Version --
    #docker run -d -p 3000:8080 --gpus all --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:cuda
    docker run -d --network=host --gpus all --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --restart always ghcr.io/open-webui/open-webui:cuda
    
    #-- General Version - CPU --
    #docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main
    
elif echo "$GPU_INFO" | grep -qi "amd"; then
    echo "AMD GPU detected."

    # -- or docker version --
    #docker pull ghcr.io/open-webui/open-webui:main
    #docker pull ghcr.io/open-webui/open-webui:ollama
    
    #-- not sure
    #docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main
    
    
else
    echo "No NVIDIA or AMD GPU found in relevant PCI slots."
    #-- CPU Only --
    docker run -d -p 3000:8080 -v ollama:/root/.ollama -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:ollama
fi

echo "

Access it from the hostip:8080 


"

#------ RAG ------------
#--- Malvius ----
# https://milvus.io/docs/install_standalone-docker.md

# apt-get install fio -y
# mkdir test-data fio --rw=write --ioengine=sync --fdatasync=1 --directory=test-data --size=2200m --bs=2300 --name=mytest
# curl -sfL https://raw.githubusercontent.com/milvus-io/milvus/master/scripts/standalone_embed.sh -o standalone_embed.sh
# bash standalone_embed.sh start
# Stop Milvus
# bash standalone_embed.sh stop
# Delete Milvus data
# bash standalone_embed.sh delete

# upgrade Milvus
# bash standalone_embed.sh upgrade
# pip3 install -U pymilvus


echo "

==============================
        Ollama Cloud

   https://ollama.com/cloud
==============================

If you want to run models in ollama cloud you must setup an account and sign in. Use the following command to generate an API token with ollama.com and a account

Command: 
    ollama signin

"

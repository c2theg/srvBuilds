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


Version:  0.0.26
Last Updated:  7/22/2025

# https://ollama.com/search


Install:
    rm install_ai.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai.sh && chmod u+x install_ai.sh


Recommended (after):
    rm update_ai_models.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_ai_models.sh && chmod u+x update_ai_models.sh

"

#-- update yourself! --
rm install_ai.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai.sh && chmod u+x install_ai.sh

#--------------------------------------------------------------------------------------------
# Install & Update Ollama to latest version using:
curl -fsSL https://ollama.com/install.sh | sh

echo "
grep MemTotal /proc/meminfo


Downloading and Installing AMD GPU Drivers...

"

lspci -k | grep -EA3 'VGA|3D|Display'
lspci | grep VGA

curl -L https://ollama.com/download/ollama-linux-amd64-rocm.tgz -o ollama-linux-amd64-rocm.tgz
sudo tar -C /usr -xzf ollama-linux-amd64-rocm.tgz

echo "


Deleting Temp download...


"
rm ollama-linux-amd64-rocm.tgz


# echo "

# Installing Nvidia CUDA Drivers...

# lspci | grep -i nvidia

# "
# Nvidia CUDA - https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_local
# wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
# sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
# wget https://developer.download.nvidia.com/compute/cuda/12.6.3/local_installers/cuda-repo-ubuntu2204-12-6-local_12.6.3-560.35.05-1_amd64.deb
# sudo dpkg -i cuda-repo-ubuntu2204-12-6-local_12.6.3-560.35.05-1_amd64.deb
# sudo cp /var/cuda-repo-ubuntu2204-12-6-local/cuda-*-keyring.gpg /usr/share/keyrings/
# sudo apt-get update
# sudo apt-get -y install cuda-toolkit-12-6
# sudo apt-get install -y nvidia-open


# echo "Installing ARM64 (Apple Mac, Pi, etc.)... \r\n "
# curl -L https://ollama.com/download/ollama-linux-arm64.tgz -o ollama-linux-arm64.tgz
# sudo tar -C /usr -xzf ollama-linux-arm64.tgz


#---- AI MODELS ----
# https://ollama.com/search

ollama list
echo "

"

#-- good for Text
echo "

Downloading DeepSeek-R1-Distill-Llama-8B ...

"

ollama run deepseek-r1:latest   # deepseek-r1:8b


echo "

Qwen-8B (Alibaba Cloud)

"
# ollama run deepseek-r1:7b
#ollama run qwen3:latest       # 8b  (from 0.5b - 110b) - Alibaba Cloud



echo "

Downloading llama3.2:latest ...

"
ollama pull llama3.2:latest        # 3b    - Meta
# llama3.1:8b



echo "


Downloading Gemma...
   - https://ollama.com/library/gemma3

   7.5GB  32K
"
ollama pull gemma3n:latest


echo "

Downloading Phi...

"
#ollama pull phi3.5          # 3.8b  - Microsoft
#ollama pull phi4           # 14b   - Microsoft
ollama pull phi4-mini-reasoning  # 3.8b - Microsoft


echo "

Downloading Mistral...

"
ollama pull mistral:7b

#------------------------------------------------------------
#ollama run tinyllama         # 1.1b
#ollama run nemotron-mini     # 4b - Nvidia
#ollama run mistral-nemo      # 12b - Mistral - Nvidia
#ollama run llama3-chatqa     # 8b - Nvidia - ChatQA
#ollama run granite3-dense:8b # 8b - IBM RAG


#-- good for Images
#ollama pull llama3.2-vision:11b    # 11b

# echo "

# Downloading llava:7b...

# "
#ollama pull llava:7b
#ollama pull llava-llama3


#--- EMBEDDINGS (RAG) -------
echo "

Downloading nomic-embed-text...

"
ollama pull nomic-embed-text
#ollama pull mxbai-embed-large
#ollama pull snowflake-arctic-embed


#--- Security (Prompt) ----
echo "

Downloading llama-guard3t...

"
ollama pull llama-guard3:latest  # 8b - Meta
#ollama run shieldgemma:latest   # 9b - Google

echo "

"
ollama list

#--- Install Python Packages ---
pip3 install requests
pip3 install ollama
pip3 install pdfplumber
pip3 install langchain langchain-core langchain-ollama langchain-community langchain_text_splitters
pip3 install unstructured unstructured[all-docs]
pip3 install fastembed
pip3 install sentence-transformers
pip3 install elevenlabs

#--- Vector Databases ---
# Milvus lite (10k - 100k vectors)
pip3 install milvus
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


#------- Install Machine Learning libs -------
pip3 install tensorflow
pip3 install scikit-learn
pip3 install torch torchvision

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
#service ollama status

#---- LLAMA Web UI --- https://github.com/open-webui/open-webui#troubleshooting
#pip3 install open-webui
#open-webui serve
# -- or docker version --
# docker pull ghcr.io/open-webui/open-webui:main
docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main
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
pip3 install -U pymilvus

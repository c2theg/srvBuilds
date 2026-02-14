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


Version:  0.1.8
Last Updated:  2/14/2026

# https://ollama.com/search

"

#-- Update yourself! --
wget -O "install_ai.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai.sh && chmod u+x install_ai.sh
wget -O "docker-compose.yml" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_compose.txt
#wget -O "update_ai_models.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_ai_models.sh && chmod u+x update_ai_models.sh

#--------------------------
sudo apt update
sudo apt install -y --no-install-recommends wget curl gnupg2 git libgl1 libglib2.0-0
sudo apt install -y jq
sudo apt install -y linux-oem-24.04b

# Check if docker is in the system's PATH
if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker is installed. Version: $(docker --version)"
else
    echo "❌ Docker is not installed."
     echo " You need docker first before running this. This will download a docker installer and run it for you. "
     wget -O "install_docker.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_docker.sh
     chmod u+x install_docker.sh
     ./install_docker.sh
fi
#----------------------------------------------------------------------------------------------------------------------------------

# Create the directory
sudo mkdir -p /usr/share/ollama/models

# Give the directory appropriate permissions for the Docker container
sudo chmod -R 777 /usr/share/ollama/models


echo "

grep MemTotal /proc/meminfo

Downloading and Installing AMD GPU / AMD Ryzen AI 9 HX PRO 370 - Drivers...

dmesg | grep -e IOMMU -e AMD-Vi


"
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
    #----- You need - nvidia-container-toolkit -------------------------
    sudo apt-get -y install cuda-toolkit-13-1
    #sudo apt-get -y install cuda-toolkit-12-6
    sudo apt-get install -y nvidia-open nvidia-driver-pinning-590
    
    #sudo apt-get install -y linux-modules-nvidia-580-open-generic-hwe-24.04
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


   
elif echo "$GPU_INFO" | grep -qi "amd"; then
    echo "AMD GPU detected."

    curl -L https://ollama.com/download/ollama-linux-amd64-rocm.tgz -o ollama-linux-amd64-rocm.tgz
    sudo tar -C /usr -xzf ollama-linux-amd64-rocm.tgz
    sudo apt install -y libdrm-amdgpu1 libhsa-runtime64-1 libhsakmt1 rocminfo
    rm ollama-linux-amd64-rocm.tgz


    sudo apt update
    # Install AMD GPU drivers with ROCm support
    # Example using version 6.4.1 (check amdgpu-install for latest)
    wget https://repo.radeon.com/amdgpu-install/6.4.1/ubuntu/noble/amdgpu-install_6.4.60401-1_all.deb
    sudo apt install ./amdgpu-install_6.4.60401-1_all.deb
    sudo amdgpu-install -y --usecase=workstation,rocm
    



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
    echo "No NVIDIA or AMD GPU found in relevant PCI-X slots."
    # echo "Installing ARM64 (Apple Mac, Pi, etc.)... \r\n "
    # curl -L https://ollama.com/download/ollama-linux-arm64.tgz -o ollama-linux-arm64.tgz
    # sudo tar -C /usr -xzf ollama-linux-arm64.tgz
fi



# if echo "$GPU_INFO" | grep -qi "nvidia"; then
#     echo "NVIDIA GPU detected."

# elif echo "$GPU_INFO" | grep -qi "amd"; then
#     echo "AMD GPU detected."
#     #docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main

# else
#     echo "No NVIDIA or AMD GPU found in relevant PCI slots."
#     #-- CPU Only --
#     #docker run -d -p 3000:8080 -v ollama:/root/.ollama -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:ollama

# fi


echo "

Download & Install Containers (Ollama, Open-WebUI, etc.)

"
docker compose up -d
sleep 10


#---- AI MODELS ----
# https://ollama.com/search

#--- force pull models ---
# docker exec -it ollama ollama pull minimax-m2.1:cloud
# docker exec -it ollama ollama pull ministral-3:8b
# docker exec -it ollama ollama pull llama3.2:3b
# docker exec -it ollama ollama pull qwen3-vl:8b
# docker exec -it ollama ollama pull qwen3-embedding:0.6b

echo "

Download & Install AI Models

"
wget -O "install_ai_models.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_models.sh && chmod +x install_ai_models.sh && ./install_ai_models.sh
sleep 10


echo "

---- List all Models ----

"

curl http://localhost:11434/api/tags | jq .

echo "

------------------------------
Hello World - Ollama! 
------------------------------

"

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


#---- Python 3 ----
echo "

Installing Python 3 for AI Developmemt...


"
if [ ! -f "install_python3.sh" ]; then
    wget -O "install_python3.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_python3.sh && chmod u+x install_python3.sh
fi

if [ ! -f "install_ai_python3_venv.sh" ]; then
    wget -O "install_ai_python3_venv.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_python3_venv.sh && chmod u+x install_ai_python3_venv.sh
    ./install_ai_python3_venv.sh
fi

#--- end Python 3 ----

echo "

==============================
        Ollama Cloud

   https://ollama.com/cloud
==============================

If you want to run models in ollama cloud you must setup an account and sign in. Use the following command to generate an API token with ollama.com and a account

Command: 
    ollama signin



ALL DONE!


Access the webui at http://localhost:3000
Ollama API at: http://localhost:11434


"

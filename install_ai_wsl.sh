#!/bin/bash
#  Version 0.0.10
#  Updated: 12/22/2025
#
#----------------------------------------------
sudo apt install nvidia-driver-580 -y

#------------------
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

sudo apt update
sudo apt upgrade

sudo apt-get update && sudo apt-get install -y --no-install-recommends curl gnupg2

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update

export NVIDIA_CONTAINER_TOOLKIT_VERSION=1.18.1-1
  sudo apt-get install -y \
      nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
      libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}

sudo nvidia-ctk runtime configure --runtime=docker

sudo systemctl restart docker

#---- Open WebUI ------
#-- General Version - CPU --
#docker pull ghcr.io/open-webui/open-webui:main
#docker run -d -p 3000:8080 -v open-webui:/app/backend/data --name open-webui ghcr.io/open-webui/open-webui:main

#-- Nvidia Version --
#docker run -d -p 3000:8080 --gpus all --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:cuda
docker run -d --network=host --gpus all --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --restart always ghcr.io/open-webui/open-webui:cuda

#-- General Version - CPU --
#docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main


echo "

 --- Windows - WSL---
1) Add Firewall rules to Windows Defender Firewall:
    8080, 11434

2) Port forward from windows to linux (wsl) container. Run Powershell as admin and enter the following:
    a) Get IP Address inside Linux container via:  ip a
    b) Update the following, with both ports, with the correct ip address:
        netsh interface portproxy add v4tov4 listenport=8080  listenaddress=0.0.0.0 connectport=8080  connectaddress=<WSL_IP>
        netsh interface portproxy add v4tov4 listenport=11434 listenaddress=0.0.0.0 connectport=11434 connectaddress=<WSL_IP>

"

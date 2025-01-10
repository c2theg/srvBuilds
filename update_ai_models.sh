#!/bin/bash
#
# https://github.com/ollama/ollama/issues/1890
# https://github.com/ollama/ollama/blob/main/docs/linux.md
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

\r\n \r\n
Version:  0.0.16                            \r\n
Last Updated:  1/10/2025

Install:
  wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_ai_models.sh && chmod u+x update_ai_models.sh


Crontab:
  5 3 5 * * /home/ubuntu/update_ai_models.sh >> /var/log/update_ai_models.log 2>&1


"

ollama --version
service ollama status


echo "\r\n \r\n \r\n"
echo "Updating Ollama.. be reinstalling it... \r\n \r\n "
curl -fsSL https://ollama.com/install.sh | sh
ollama -v


#echo "Installing Nvidia CUDA Drivers... \r\n \r\n "
# Nvidia CUDA - https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=22.04&target_type=deb_local
# wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
# sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
# wget https://developer.download.nvidia.com/compute/cuda/12.6.3/local_installers/cuda-repo-ubuntu2204-12-6-local_12.6.3-560.35.05-1_amd64.deb
# sudo dpkg -i cuda-repo-ubuntu2204-12-6-local_12.6.3-560.35.05-1_amd64.deb
# sudo cp /var/cuda-repo-ubuntu2204-12-6-local/cuda-*-keyring.gpg /usr/share/keyrings/
# sudo apt-get update
# sudo apt-get -y install cuda-toolkit-12-6
# sudo apt-get install -y nvidia-open


echo "Installing AMD GPU Drivers... \r\n "
curl -L https://ollama.com/download/ollama-linux-amd64-rocm.tgz -o ollama-linux-amd64-rocm.tgz
sudo tar -C /usr -xzf ollama-linux-amd64-rocm.tgz


# echo "Installing ARM64 (Apple Mac, Pi, etc.)... \r\n "
# curl -L https://ollama.com/download/ollama-linux-arm64.tgz -o ollama-linux-arm64.tgz
# sudo tar -C /usr -xzf ollama-linux-arm64.tgz


echo "\r\n \r\n \r\n"
echo "Listing AI Models... \r\n \r\n \r\n"
ollama list


echo "\r\n \r\n \r\n"
echo "Updating all AI Models... \r\n \r\n \r\n "
ollama list | tail -n +2 | awk '{print $1}' | while read -r model; do
  ollama pull $model
done


echo "Listing All updated AI Models... \r\n \r\n \r\n"
ollama list


echo "\r\n \r\n DONE! \r\n \r\n"

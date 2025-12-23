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


Version:  0.0.22
Last Updated:  12/22/2025


Install:
  rm update_ai_models.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_ai_models.sh && chmod u+x update_ai_models.sh


Recommended (first):
  rm install_ai.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai.sh && chmod u+x install_ai.sh


Crontab:
  5 3 5 * * /home/ubuntu/update_ai_models.sh >> /var/log/update_ai_models.log 2>&1


"

#-- update yourself! --
rm update_ai_models.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_ai_models.sh && chmod u+x update_ai_models.sh


ollama --version
#service ollama status

echo "


Updating Ollama or re-installing it...


"
#curl -fsSL https://ollama.com/install.sh | sh



ollama -v


echo "


Listing AI Models...


"
ollama list



echo "


Updating all AI Models...


"
# ollama list | tail -n +2 | awk '{print $1}' | while read -r model; do
#   ollama pull $model
# done
ollama list | tail -n +2 | awk '{print $1}' | xargs -I {} ollama pull {}


echo "

Listing All updated AI Models...

"
ollama list


echo "

DONE!


Update OpenWebUI

docker pull ghcr.io/open-webui/open-webui:main
docker rm -f open-webui
docker run -d -p 3000:8080 -v open-webui:/app/backend/data --name open-webui ghcr.io/open-webui/open-webui:main




"

docker stop open-webui
docker rm -f open-webui
docker system prune --all --volumes


#-- General Version - CPU --
#docker pull ghcr.io/open-webui/open-webui:main
#docker run -d -p 3000:8080 -v open-webui:/app/backend/data --name open-webui ghcr.io/open-webui/open-webui:main

#-- Nvidia Version --
docker run -d -p 3000:8080 --gpus all --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:cuda





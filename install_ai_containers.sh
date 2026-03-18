#!/bin/sh
#-------------------------------------------------------------
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


Version:  0.0.10
Last Updated:  3/18/2026

"

wget -O "install_ai_containers.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_containers.sh && chmod u+x install_ai_containers.sh
#-------------------------------------------------------------
if [ ! -d "/usr/share/ollama" ]; then
    echo "Directory /usr/share/ollama does not exist. Creating it..."
    mkdir -p /usr/share/ollama
fi

#--- stop and remove any existing ollama containers and images ----
docker stop ollama && docker rm ollama
docker rmi ollama/ollama:latest
#-------------------------------------------------------------------

cd /usr/share/ollama
wget -O "docker-compose.yml" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_compose.txt
docker compose up -d

#--- vector databases ----
# https://milvus.io/docs/install_standalone-docker.md
# https://raw.githubusercontent.com/milvus-io/milvus/master/scripts/standalone_embed.sh
sudo docker run -d \
    --name milvus-standalone \
    --security-opt seccomp:unconfined \
    -e ETCD_USE_EMBED=true \
    -e ETCD_DATA_DIR=/var/lib/milvus/etcd \
    -e ETCD_CONFIG_PATH=/milvus/configs/embedEtcd.yaml \
    -e COMMON_STORAGETYPE=local \
    -e DEPLOY_MODE=STANDALONE \
    -v $(pwd)/volumes/milvus:/var/lib/milvus \
    -v $(pwd)/embedEtcd.yaml:/milvus/configs/embedEtcd.yaml \
    -v $(pwd)/user.yaml:/milvus/configs/user.yaml \
    -p 19530:19530 \
    -p 9091:9091 \
    -p 2379:2379 \
    --health-cmd="curl -f http://localhost:9091/healthz" \
    --health-interval=30s \
    --health-start-period=90s \
    --health-timeout=20s \
    --health-retries=3 \
    milvusdb/milvus:v2.6.8 \
    milvus run standalone  1> /dev/null


#--- Time Series Database -----
# docker run -d --name influxdb -p 8086:8086 influxdb:latest


#--- graph database(s) -----
# docker run \
#     --name neo4j-server \
#     --publish=7474:7474 --publish=7687:7687 \
#     --volume=$HOME/neo4j/data:/data \
#     --env NEO4J_AUTH=neo4j/your_password \
#     neo4j:latest


#---- APPLICATIONS ---------
# docker run -it --rm -p 8888:8888 jupyter/datascience-notebook:latest
# docker run -it --rm -p 5678:5678 n8nio/n8n:latest

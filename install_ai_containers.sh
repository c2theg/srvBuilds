#!/bin/sh
#-------------------------------------------------------------
#  
#  Updated: 1/6/2026
#  Version: 0.0.6
#-------------------------------------------------------------

docker run -it --rm ollama/ollama:latest


#--- vector databases ----
#docker run -it --rm -p 6333:6333 qdrant/qdrant

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

    

#--- graph database(s) -----
docker run \
    --name neo4j-server \
    --publish=7474:7474 --publish=7687:7687 \
    --volume=$HOME/neo4j/data:/data \
    --env NEO4J_AUTH=neo4j/your_password \
    neo4j:latest



#---- APPLICATIONS ---------
# docker run -it --rm -p 8888:8888 jupyter/datascience-notebook:latest
# docker run -it --rm -p 5678:5678 n8nio/n8n:latest


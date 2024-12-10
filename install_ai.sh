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

\r\n \r\n
Version:  0.0.8                            \r\n
Last Updated:  12/10/2024

"
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
# Install & Update Ollama to latest version using: 
curl -fsSL https://ollama.com/install.sh | sh
ollama list

#-- good for Text
ollama pull llama3.2
#ollama pull gemma2:2b
#ollama pull phi3.5

#-- good for Images
#ollama pull llama3.2-vision:11b
ollama pull llava:7b
#ollama pull llava-llama3

#--- EMBEDDINGS (RAG) -------
ollama pull nomic-embed-text
#ollama pull mxbai-embed-large

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

pip3 install pandas
pip3 install numpy

#--- Vector Databases ---
# Milvus lite (10k - 100k vectors)
pip3 install milvus
# Milvus Standalone (single machine (1M - 10M Vectors) / Milvus-cluster (10B vectors)
pip3 install -U pymilvus
#in memory vector database, single node
pip3 install chromadb
#-------------------------------
ollama list
ollama --version


#---- LLAMA Web UI ---
# pip3 install open-webui
# open-webui serve
# -- or docker version --
# docker pull ghcr.io/open-webui/open-webui:main
# docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main
# Access it from the hostip:8080

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
Version:  0.0.2                            \r\n
Last Updated:  12/5/2024

"
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
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

#--- Vector Databases ---
pip3 install chromadb
#pip3 install elasticsearch

#-------------------------------
ollama list

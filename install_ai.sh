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
Version:  0.0.1                            \r\n
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

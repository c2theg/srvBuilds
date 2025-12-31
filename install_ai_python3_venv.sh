#!/usr/bin/env bash
#set -e
set -euo pipefail
VENV_BASE="/opt/python3_shared"

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


Version:  0.0.5
Last Updated:  12/31/2025

What this does:
    Creates a GLOBAL Python3 Virtual Environment (I know you think that defeats the entire reason for an venv... it does not. 
    You need a global venv so that you dont have duplicate versions of everything installed. Its global so many python scripts 
    can access the shared resources!


Global Path:  $VENV_BASE/venv


Install:
    rm install_ai_python3_venv.sh && wget https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_python3_venv.sh && chmod u+x install_ai_python3_venv.sh

"

VENV_DIR="$VENV_BASE/venv"

# Create venv if it doesn't exist
if [[ ! -d "$VENV_DIR" ]]; then
    python3 -m venv "$VENV_DIR"
fi

# Ensure base directory exists
if [[ ! -d "$VENV_BASE" ]]; then
    sudo mkdir -p "$VENV_BASE"
    sudo chown -R "$USER:$USER" "$VENV_BASE"
fi

# Create venv if missing
if [[ ! -d "$VENV_DIR" ]]; then
    python3 -m venv "$VENV_DIR"
fi

# Activate venv (bash built-in)
source "$VENV_DIR/bin/activate"

# Upgrade core tooling
pip install --upgrade pip setuptools wheel

#--------------- Install shared packages ---------------
pip install requests flask redis
pip3 install requests urllib3 beautifulsoup4 pymongo

pip3 install ollama
pip3 install pdfplumber
pip3 install langchain langchain-core langchain-ollama langchain-community langchain_text_splitters
pip3 install unstructured unstructured[all-docs]
pip3 install fastembed
pip3 install sentence-transformers
pip3 install elevenlabs
#--- Vector Databases ---
# Milvus lite (10k - 100k vectors)
#pip3 install milvus
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

# install NLP Libraries
pip3 install textblob nltk spacy wordcloud

# Machine Learning
pip3 install scikit-learn joblib

# Core email processing
pip install html2text 

# For Transformer models (GPU recommended)
pip install torch transformers datasets

# Download NLTK data
python -m nltk.downloader punkt stopwords wordnet averaged_perceptron_tagger

# Download spaCy model
python -m spacy download en_core_web_sm

#------- Install Machine Learning libs -------
pip3 install torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip3 install tensorflow
pip3 install scikit-learn
pip3 install torchvision

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

#------------------- End of Shared ---------------------

# Deactivate cleanly
deactivate

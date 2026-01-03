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


Version:  0.0.17
Last Updated:  1/3/2026

What this does:
    Creates a GLOBAL Python3 Virtual Environment (I know you think that defeats the entire reason for an venv... it does not. 
    You need a global venv so that you dont have duplicate versions of everything installed. Its global so many python scripts 
    can access the shared resources!


Global Path:  $VENV_BASE/venv/bin/activate


Install:
     wget -O 'install_ai_python3_venv.sh' https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_python3_venv.sh && chmod u+x install_ai_python3_venv.sh

"
#---- OS Level -----
sudo apt install -y tesseract-ocr


#-------- Python3 - PIP -----------------
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
pip3 install requests flask
pip3 install requests urllib3 beautifulsoup4 pymongo
pip3 install html2text 

#------- AI ----------------
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
pip3 install textblob wordcloud

# Machine Learning
pip3 install scikit-learn joblib

pip3 install transformers # https://pypi.org/project/transformers/
pip3 install datasets # https://pypi.org/project/datasets/

#--- NLTK ---
export NLTK_DATA="$VENV_BASE/nltk_data"

pip3 install nltk
#python3 -m nltk.downloader
python3 -m nltk.downloader -d $VENV_BASE/nltk_data all

echo "
To include nltk in your python code:

import nltk
# Append a new search path
nltk.data.path.append('$VENV_BASE/nltk_data')

# Download to a specific folder
nltk.download('punkt', download_dir='$VENV_BASE/nltk_data')


"

python3 -m punkt stopwords wordnet averaged_perceptron_tagger


# Download spaCy model - https://spacy.io/usage/models  |  https://spacy.io/models/en |  https://github.com/explosion/spacy-models/releases
pip3 install spacy
#python -m spacy download en_core_web_sm # 0 keys, 0 unique vectors (0 dimensions) - 12 MB
#python -m spacy download en_core_web_md # 685k keys, 20k unique vectors (300 dimensions) -  31 MB
#python -m spacy download en_core_web_lg # 685k keys, 343k unique vectors (300 dimensions) - 382 MB
#python -m spacy download en_core_web_trf # 0 keys, 0 unique vectors (0 dimensions) - 436 MB

#--- Custom Path ---
# https://github.com/explosion/spacy-models/releases/tag/en_core_web_md-3.8.0
wget -O "en_core_web_md.tar.gz" https://github.com/explosion/spacy-models/releases/download/en_core_web_md-3.8.0/en_core_web_md-3.8.0.tar.gz
unzip en_core_web_md.tar.gz -d $VENV_BASE/spacy/

echo "
To include Spacy into your python:


import spacy
nlp = spacy.load('$VENV_BASE/spacy/en_core_web_md') # load package from a directory

doc = nlp('This is a sentence.')


"
#------- Install Machine Learning libs -------
pip3 install torch torchvision
pip3 install torchaudio --index-url https://download.pytorch.org/whl/cu118
pip3 install tensorflow
pip3 install scikit-learn

#pip3 install catboost
# LightGBM -> https://lightgbm.readthedocs.io/en/stable/Installation-Guide.html
pip3 install keras # Yolo3 requirement
#pip3 install gym  # -> https://github.com/openai/gym
#pip3 install xgboost # -> https://xgboost.readthedocs.io/en/stable/install.html

#--- Deep Learning ---
pip3 install tf-keras

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

#--- OCR ---
# Install EasyOCR
pip3 install easyocr
pip3 install pytesseract pillow

#---- PaddleOCR -----
#--- CPU ---
python -m pip install paddlepaddle
#python -m pip install paddleocr
python -m pip install "paddleocr[all]"

#--- GPU - Nvidia ---
# Example for CUDA 12.6 (2026 stable)
#python -m pip install paddlepaddle-gpu==3.0.0 -i https://www.paddlepaddle.org.cn/packages/stable/cu126/

#- DocTR (Document Text Recognition) is a high-performance Python OCR library --
pip3 install "python-doctr[viz,html,contrib]"
pip3 install "python-doctr[torch]"
pip3 install "python-doctr[tf]"

#--- Keras ---
pip3 install keras-ocr

#----- LLM -----------------
# https://ollama.com/library/qwen3-vl
# ollama run qwen3-vl
# qwen3-vl:8b

#--- https://reducto.ai/blog/introducing-rolmocr-open-source-ocr-model --
pip3 install reductoai

#------------------- End of Shared ---------------------
# Deactivate cleanly
deactivate


# source /opt/python3_shared/venv/bin/activate
echo " 
Done installing/Updating!

To Activate the Python VEnv, issue the following:


source $VENV_BASE/venv/bin/activate


"

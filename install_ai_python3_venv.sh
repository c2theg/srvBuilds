#!/usr/bin/env bash
#set -e
set -euo pipefail
VENV_BASE="${VENV_BASE:-/opt/python3_shared}"
AI_DBS_BASE="${AI_DBS_BASE:-/opt/ai_dbs}"
VENV_RECREATE=0
PYTHON_VERSION_MM=""

#mkdir -p $VENV_BASE
mkdir -p $AI_DBS_BASE

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


Version:  0.2.40
Last Updated:  2/18/2026

What this does:
    Creates a GLOBAL Python3 Virtual Environment (I know you think that defeats the entire reason for an venv... it does not.
    You need a global venv so that you dont have duplicate versions of everything installed. Its global so many python scripts
    can access the shared resources!


Global Path:  $VENV_BASE/venv/bin/activate


"
#-- Install / Update yourself! --
wget -O "install_ai_python3_venv.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_python3_venv.sh && chmod u+x install_ai_python3_venv.sh
#----------------------

# Print out current python3 and pip version
echo "System Python: $(python3 --version 2>/dev/null || echo "Not found")"
echo "System Pip: $(pip3 --version 2>/dev/null || echo "Not found")"
echo "VENV_BASE: $VENV_BASE"
echo "AI_DBS_BASE: $AI_DBS_BASE"


usage() {
  cat <<'EOF'
Usage: install_ai_python3_venv.sh [--venv-base PATH] [--ai-dbs-base PATH] [--recreate]

Environment:
  VENV_BASE   Base folder for the shared venv (default: /opt/python3_shared)
  AI_DBS_BASE Base folder for persistent AI DB storage (default: /opt/ai_dbs)

Notes:
  - This script accepts any Python 3.7+.
  - Some packages may not publish wheels for your Python version; the script
    will attempt all installs and report failures at the end.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --venv-base)
      VENV_BASE="${2:-}"
      shift 2
      ;;
    --ai-dbs-base)
      AI_DBS_BASE="${2:-}"
      shift 2
      ;;
    --recreate)
      VENV_RECREATE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
is_linux() { [[ "$(uname -s)" == "Linux" ]]; }

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

ensure_writable_dir() {
  local dir="$1"
  if mkdir -p "$dir" >/dev/null 2>&1; then
    return 0
  fi

  if command -v sudo >/dev/null 2>&1; then
    sudo mkdir -p "$dir"
    sudo chown -R "${USER}:$(id -gn)" "$dir" || true
    return 0
  fi

  return 1
}

pick_python() {
  local python_bin=""
  if command -v python3.14 >/dev/null 2>&1; then
    python_bin="python3.14"
  elif command -v python3 >/dev/null 2>&1; then
    python_bin="python3"
  elif command -v python >/dev/null 2>&1; then
    python_bin="python"
  else
    echo "No Python found. Install Python 3.7+ and re-run." >&2
    exit 1
  fi

  # Require 3.7+
  local major_minor
  major_minor="$("$python_bin" -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null || echo "")"
  if [[ -z "$major_minor" ]]; then
    echo "Failed to run $python_bin to detect version." >&2
    exit 1
  fi

  local major="${major_minor%%.*}"
  local minor="${major_minor##*.}"
  if [[ "$major" -ne 3 || "$minor" -lt 7 ]]; then
    echo "Detected $python_bin is Python $major_minor; Python 3.7+ is required." >&2
    exit 1
  fi

  PYTHON_VERSION_MM="$major_minor"
  echo "$python_bin"
}



#---- OS Level (best-effort; you can skip and install these manually) -----
if is_linux; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y python3-dev build-essential tesseract-ocr
  else
    echo "Linux detected, but apt-get not found. Install build tools + tesseract manually." >&2
  fi
elif is_macos; then
  if command -v brew >/dev/null 2>&1; then
    brew install tesseract || true
  else
    echo "macOS detected; install tesseract via Homebrew: brew install tesseract" >&2
  fi
fi

#-------- Python3 - PIP -----------------
PYTHON_BIN="$(pick_python)"
VENV_DIR="$VENV_BASE/venv"

# Ensure base directory exists (fallback to $HOME if /opt is not writable)
if ! ensure_writable_dir "$VENV_BASE"; then
  VENV_BASE="${HOME}/.python3_shared"
  VENV_DIR="$VENV_BASE/venv"
  ensure_writable_dir "$VENV_BASE"
fi

if ! ensure_writable_dir "$AI_DBS_BASE"; then
  AI_DBS_BASE="${HOME}/.ai_dbs"
  ensure_writable_dir "$AI_DBS_BASE"
fi

CHROMA_PERSIST_DIRECTORY="${AI_DBS_BASE}/chroma"
MILVUS_PERSIST_DIRECTORY="${AI_DBS_BASE}/milvus"
MILVUS_DATA_DIR="$MILVUS_PERSIST_DIRECTORY"
MILVUS_LITE_DATA_DIR="$MILVUS_PERSIST_DIRECTORY"
export AI_DBS_BASE CHROMA_PERSIST_DIRECTORY MILVUS_PERSIST_DIRECTORY MILVUS_DATA_DIR MILVUS_LITE_DATA_DIR
mkdir -p "$CHROMA_PERSIST_DIRECTORY" "$MILVUS_PERSIST_DIRECTORY"

VENV_PY="$VENV_DIR/bin/python"

if [[ -d "$VENV_DIR" && "$VENV_RECREATE" -eq 1 ]]; then
  rm -rf "$VENV_DIR"
fi

# Create venv if missing
if [[ ! -d "$VENV_DIR" ]]; then
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

# Ensure venv python is runnable
if [[ ! -x "$VENV_PY" ]]; then
  echo "Venv Python not found at: $VENV_PY" >&2
  exit 1
fi

# Validate venv Python version (avoid silently using an old venv)
venv_version="$("$VENV_PY" -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null || echo "")"
if [[ -z "$venv_version" ]]; then
  echo "Failed to detect venv Python version." >&2
  exit 1
fi
if [[ "$venv_version" != "$PYTHON_VERSION_MM" ]]; then
  echo "Existing venv uses Python $venv_version (expected $PYTHON_VERSION_MM). Re-run with --recreate to rebuild it." >&2
  #exit 1
fi

PIP_BASE=( "$VENV_PY" -m pip )

pip_failures=()
pip_install() {
  if ! "${PIP_BASE[@]}" install "$@"; then
    pip_failures+=( "pip install $*" )
    return 0
  fi
}

pip_uninstall() {
  if ! "${PIP_BASE[@]}" uninstall -y "$@"; then
    pip_failures+=( "pip uninstall -y $*" )
    return 0
  fi
}

# Ensure pip exists for this interpreter (some Python builds omit pip)
"$VENV_PY" -m ensurepip --upgrade >/dev/null 2>&1 || true

#---- Detect system CPU / GPU -------
GPU_TYPE="cpu"
CUDA_VERSION=""
ROCM_VERSION=""

uname_s=$(uname 2>/dev/null || echo "")

if [ "$uname_s" = "Darwin" ]; then
  # macOS: treat Apple GPU as "mac". (NVIDIA is effectively obsolete on modern macOS.)
  if system_profiler SPDisplaysDataType 2>/dev/null | grep -qi "Apple"; then
    GPU_TYPE="mac"
  elif system_profiler SPDisplaysDataType 2>/dev/null | grep -qi "AMD"; then
    GPU_TYPE="amd"
  else
    GPU_TYPE="cpu"
  fi
else
  # Linux: prefer NVIDIA if present.
  if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_TYPE="nvidia"

    # CUDA version checks (best-effort)
    # 1) Prefer NVCC if installed
    if command -v nvcc >/dev/null 2>&1; then
      # Example: "Cuda compilation tools, release 12.3, V12.3.107"
      CUDA_VERSION=$(nvcc --version 2>/dev/null | awk '/release/ {for (i=1;i<=NF;i++) if ($i=="release") {gsub(/,/, "", $(i+1)); print $(i+1); exit}}')
    fi
    # 2) Fallback to nvidia-smi reported CUDA
    if [ -z "$CUDA_VERSION" ]; then
      # Example: "... CUDA Version: 12.2"
      CUDA_VERSION=$(nvidia-smi 2>/dev/null | awk -F'CUDA Version: ' 'NF>1 {split($2,a," "); print a[1]; exit}')
    fi
    # 3) Fallback to version.txt if present
    if [ -z "$CUDA_VERSION" ] && [ -r /usr/local/cuda/version.txt ]; then
      # Example: "CUDA Version 12.2.0"
      CUDA_VERSION=$(awk '{for (i=1;i<=NF;i++) if ($i=="Version") {print $(i+1); exit}}' /usr/local/cuda/version.txt 2>/dev/null)
    fi

  else
    # AMD detection (ROCm-aware, plus generic PCI vendor check if available)
    AMD_FOUND=""

    # ROCm toolchain present?
    if command -v rocminfo >/dev/null 2>&1 || command -v rocm-smi >/dev/null 2>&1; then
      AMD_FOUND="yes"
    fi

    # Generic AMD/ATI via PCI (common on Ubuntu/Rocky; may be missing in minimal installs)
    if [ -z "$AMD_FOUND" ] && command -v lspci >/dev/null 2>&1; then
      if lspci 2>/dev/null | grep -Ei "VGA|3D|Display" | grep -Ei "AMD|ATI" >/dev/null 2>&1; then
        AMD_FOUND="yes"
      fi
    fi

    if [ -n "$AMD_FOUND" ]; then
      GPU_TYPE="amd"

      # ROCm version checks (best-effort)
      # 1) /opt/rocm/.info/version is common on ROCm installs
      if [ -r /opt/rocm/.info/version ]; then
        ROCM_VERSION=$(head -n 1 /opt/rocm/.info/version 2>/dev/null | tr -d ' \t\r\n')
      fi
      # 2) rocm-smi sometimes prints a version string (varies by version/distribution)
      if [ -z "$ROCM_VERSION" ] && command -v rocm-smi >/dev/null 2>&1; then
        ROCM_VERSION=$(rocm-smi --version 2>/dev/null | awk 'NR==1{print $NF; exit}')
      fi
      # 3) rocminfo may include "ROCm" lines (format varies)
      if [ -z "$ROCM_VERSION" ] && command -v rocminfo >/dev/null 2>&1; then
        ROCM_VERSION=$(rocminfo 2>/dev/null | awk '/ROCm/ {print $NF; exit}')
      fi
    fi
  fi
fi
echo "


Detected GPU_TYPE = $GPU_TYPE


"
#---- end cpu gpu detection -----
#echo "SETUPTOOLS_USE_DISTUTILS=$SETUPTOOLS_USE_DISTUTILS"

# 1) remove the pip startup hook (this is the part breaking the build subprocess)
pip_uninstall pip-system-certs pip_system_certs truststore

# 2) refresh build tooling in the venv
pip_install -U pip setuptools wheel packaging

#--------------- Install shared packages ---------------
pip_install requests urllib3 beautifulsoup4
pip_install html2text

#------- AI ----------------
pip_install ollama


#--- Langchain ---
pip_install "langchain-core>=1.2.5,<2.0.0" langchain-classic==1.0.1
pip_install -U langchain langchain-core langchain-ollama langchain-community langchain-text-splitters

echo "

To verify langchain install:
    activate the venv and run:
        source $VENV_DIR/bin/activate
        pip list | grep langchain


"
#--- Unstructured ---
pip_install "unstructured[all-docs]"


#--- FastEmbed ---
pip_install fastembed


#--- Sentence Transformers ---
pip_install sentence-transformers


#--- ElevenLabs ---
pip_install elevenlabs


#--- Vector Databases ---
# Milvus lite (10k - 100k vectors)
pip_install milvus
# Milvus Standalone (single machine (1M - 10M Vectors) / Milvus-cluster (10B vectors)
pip_install -U pymilvus
#in memory vector database, single node
pip_install chromadb
#------- Install Data Science libs -------
pip_install matplotlib
pip_install numpy
pip_install pandas
pip_install scipy
pip_install "dask[complete]"

#- visuals -
pip_install bokeh # https://bokeh.org/
pip_install seaborn # https://seaborn.pydata.org/installing.html
pip_install plotly # https://plotly.com/python/getting-started/

pip_install textblob wordcloud
pip_install scikit-learn joblib

# https://pypi.org/project/transformers/
pip_install transformers

# https://pypi.org/project/datasets/
pip_install datasets

#--- PDF Processing ----
pip_install pdfplumber

# https://github.com/pymupdf/PyMuPDF
pip_install PyMuPDF
pip_install pymupdf-fonts
pip_install fonttools

# https://github.com/ocrmypdf/OCRmyPDF
#pip_install ocrmypdf

pip_install -U pypdfium2
pip_install -U ocrmypdf


#--- NLTK --- https://www.nltk.org/data.html
echo "

Installing NLTK...


"

export NLTK_DATA="$VENV_BASE/nltk_data"
#python3 -m pip install nltk
pip_install nltk
if [ [ -z "${SKIP_NLTK_DATA:-}" ] && [ ! -d "$VENV_BASE/nltk_data" ] ]; then
    echo "

    NLTK Data not found, so downloading... ( $VENV_DIR/nltk_data/ )

    "

    mkdir -p "$VENV_BASE/nltk_data/"
    "$VENV_PY" -m nltk.downloader -d "$VENV_BASE/nltk_data" all || true

    "$VENV_PY" -m nltk.downloader -d "$VENV_BASE/nltk_data" averaged_perceptron_tagger_eng || true
    "$VENV_PY" -m nltk.downloader -d "$VENV_BASE/nltk_data" punkt_eng || true
    "$VENV_PY" -m nltk.downloader -d "$VENV_BASE/nltk_data" popular_eng || true
    "$VENV_PY" -m nltk.downloader -d "$VENV_BASE/nltk_data" stopwords_eng || true
    "$VENV_PY" -m nltk.downloader -d "$VENV_BASE/nltk_data" averaged_perceptron_tagger || true

    #python3 -m nltk.downloader -d $VENV_BASE/nltk_data punkt
    #python3 -m nltk.downloader -d $VENV_BASE/nltk_data popular
    #python3 -m nltk.downloader -d $VENV_BASE/nltk_data stopwords
    #python3 -m nltk.downloader -d $VENV_BASE/nltk_data averaged_perceptron_tagger
else
   echo "NLTK Data found, so not updating! "
fi


echo "

To include nltk in your python code:

import nltk
# Append a new search path
nltk.data.path.append('$VENV_BASE/nltk_data')

# Download to a specific folder
nltk.download('punkt', download_dir='$VENV_BASE/nltk_data')

"

#--- spaCy model - https://spacy.io/usage/models  |  https://spacy.io/models/en |  https://github.com/explosion/spacy-models/releases
pip_install spacy
if [ ! -d "$VENV_BASE/spacy"]; then
    mkdir -p $VENV_BASE/spacy
    # Prefer wheel install (no custom extract paths).
    pip_install "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl"
    pip_install "https://github.com/explosion/spacy-models/releases/download/en_core_web_md-3.8.0/en_core_web_md-3.8.0-py3-none-any.whl"

    #"$VENV_PY" -m spacy download en_core_web_sm
    #"$VENV_PY" -m spacy download en_core_web_md

else
    echo "Spacy found, so not updating! "
fi


echo "
To include Spacy into your python:


import spacy
nlp = spacy.load('en_core_web_md')

doc = nlp('This is a sentence.')


"

pip_install stopwordsiso stop-words


#--- huggingface models ---
if [ ! -d "$VENV_BASE/huggingface"]; then
    mkdir -p $VENV_BASE/huggingface
fi

#------- Install Machine Learning libs -------
# - PyTorch - Customize the download - https://pytorch.org/get-started/locally/

# POSIX sh GPU detection for macOS + Linux (Ubuntu/Rocky), with CUDA/ROCm version hints.
# Outputs: GPU_TYPE (nvidia|amd|mac|cpu), and optionally CUDA_VERSION / ROCM_VERSION.

echo "

   --- PyTorch ---


"
if [ ! -d "$VENV_BASE/torch" ]; then
    mkdir -p $DATA_DIR/torch
fi


if [ $GPU_TYPE = "nvidia"  ]; then
    echo "Nvidia GPU - Detected! "
    [ -n "$CUDA_VERSION" ] && echo "CUDA_VERSION=$CUDA_VERSION"
    # for Nvidia CUDA - (Note: Replace cu126 with the specific CUDA version, such as cu128, if you are targeting a newer toolkit)
    pip_install torch torchaudio torchvision --index-url https://download.pytorch.org/whl/cu130 # Nvidia - CUDA - Latest 1/3/2026
elif [ $GPU_TYPE = "amd"  ]; then
    echo "AMD GPU - Detected"
    [ -n "$ROCM_VERSION" ] && echo "ROCM_VERSION=$ROCM_VERSION"
    pip_install torch torchvision --index-url https://download.pytorch.org/whl/rocm6.4
elif [ $GPU_TYPE = "mac"  ]; then
    echo "Mac OSX CPU/GPU Detected "
    # OSX MAC CPU / GPU
    pip_install torch torchvision
else
    echo "No GPU detected. falling back to CPU only! "
    # CPU Only!
    pip_install torch torchvision --index-url https://download.pytorch.org/whl/cpu
fi


echo "---  Exporting Environment Variables to .bashrc ---"
echo "export HF_HOME='$VENV_BASE/huggingface'" >> ~/.bashrc
echo "export NLTK_HOME='$VENV_BASE/nltk_data'" >> ~/.bashrc
echo "export SPACY_HOME='$VENV_BASE/spacy'" >> ~/.bashrc
echo "export TORCH_HOME='$VENV_BASE/torch'" >> ~/.bashrc


#----------------------------------------------
pip_install tensorflow
pip_install scikit-learn

#pip3 install catboost
# LightGBM -> https://lightgbm.readthedocs.io/en/stable/Installation-Guide.html
pip_install keras # Yolo3 requirement
#pip3 install gym  # -> https://github.com/openai/gym
#pip3 install xgboost # -> https://xgboost.readthedocs.io/en/stable/install.html

#--- Deep Learning ---
pip_install tf-keras

#------- Generative AI -------
pip_install dalle2-pytorch # -> https://github.com/lucidrains/DALLE2-pytorch
pip_install pyro-ppl # -> https://pyro.ai/examples/intro_long.html
#pip3 install glm_saga # -> https://pytorch.org/blog/empowering-models-performance/
# pip install imageai --upgrade   |  ImageAI #-> https://imageai.readthedocs.io/en/latest/#:~:text=ImageAI%20is%20a%20python%20library,and%20few%20lines%20of%20code.
# StyleGen #-> https://github.com/NVlabs/stylegan2
#pip3 install flax # -> https://flax.readthedocs.io/en/latest/
#pip3 install -U jax # -> Many Install options depending on hardware -> https://github.com/jax-ml/jax
# NeRF -> https://github.com/bmild/nerf

#------- Computer Vision / Real-Time Object Detection -------
pip_install opencv-python # https://docs.opencv.org/4.x/d6/d00/tutorial_py_root.html
# Darknet # https://github.com/mdv3101/darknet-yolov3 |  https://pjreddie.com/darknet/
# pip3 install YOLOv3 # -> https://pjreddie.com/darknet/yolo/ | https://viso.ai/deep-learning/yolov3-overview/
# pip3 install yolo-v4 #-> https://github.com/philipperemy/python-darknet-yolo-v4

#- https://huggingface.co/datasets?task_categories=task_categories%3Aimage-to-text
# google/imageinwords  # https://huggingface.co/datasets/google/imageinwords

#--- OCR ---
# Install EasyOCR
pip_install easyocr
pip_install pytesseract pillow

#---- PaddleOCR -----
#--- CPU ---
pip_install paddlepaddle
#python -m pip install paddleocr
pip_install "paddleocr[all]"

#--- GPU - Nvidia ---
# Example for CUDA 12.6 (2026 stable)
#python -m pip install paddlepaddle-gpu==3.0.0 -i https://www.paddlepaddle.org.cn/packages/stable/cu126/

#- DocTR (Document Text Recognition) is a high-performance Python OCR library --
pip_install "python-doctr[viz,html,contrib]"
pip_install "python-doctr[torch]"
#pip_install "python-doctr[tf]"

#--- Keras ---
pip_install keras-ocr

#----- LLM -----------------
# https://ollama.com/library/qwen3-vl
# ollama run qwen3-vl
# qwen3-vl:8b

#--- https://reducto.ai/blog/introducing-rolmocr-open-source-ocr-model --
pip_install reductoai

#------------------- End of Shared ---------------------
if (( ${#pip_failures[@]} > 0 )); then
  echo ""
  echo "Some pip installs failed (often due to missing wheels for your Python version):" >&2
  printf ' - %s\n' "${pip_failures[@]}" >&2
  exit 1
fi


# source /opt/python3_shared/venv/bin/activate

sudo chown -R $USER:$USER $VENV_BASE
sudo chown -R $USER:$USER $AI_DBS_BASE

echo "
Done installing/Updating!

To Activate the Python VEnv, issue the following:


source $VENV_BASE/venv/bin/activate

Persistent DB paths (exported by this script):
  AI_DBS_BASE=$AI_DBS_BASE
  CHROMA_PERSIST_DIRECTORY=$CHROMA_PERSIST_DIRECTORY
  MILVUS_PERSIST_DIRECTORY=$MILVUS_PERSIST_DIRECTORY


"

#alias myproject="source $VENV_BASE/venv/bin/activate"
echo "alias activate_env=\"source $VENV_BASE/venv/bin/activate\"" >> ~/.bashrc
#echo "alias activate_env=\"source /opt/python3_shared/venv/bin/activate\"" >> ~/.bashrc

echo "Added alias: activate_env -> source $VENV_BASE/venv/bin/activate"
echo "Run 'activate_env' to activate the virtual environment"
echo "You can also use: source $VENV_BASE/venv/bin/activate"
echo "You must restart your shell or run 'source ~/.bashrc' to use the new alias


"

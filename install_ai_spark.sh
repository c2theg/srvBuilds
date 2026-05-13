#!/bin/sh
# clear
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


Version:  0.0.20
Last Updated:  5/13/2026

Update Yourself:
  wget -O 'install_ai_spark.sh' 'https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_spark.sh' && chmod u+x install_ai_spark.sh


  YOU MUST HAVE A HUGGINGFACE ACCOUNT AND TOKEN TO DOWNLOAD MODELS!
    *** Update 'HF_TOKEN' on line 35 before running this script! ***
        Huggingface models:   https://huggingface.co/models


"
# =============================================
# CONFIGURATION — set these before running
# =============================================
HF_TOKEN=""                  # HuggingFace token — fallback if not in .env
                             # Get yours at: https://huggingface.co/settings/tokens
BASE_DIR="/opt/models"       # All paths derive from here — change this one line to relocate everything

MODELS_DIR="$BASE_DIR/vllm"           # Where all models will be downloaded
VLLM_VENV="$BASE_DIR/vllm-install/.vllm"  # venv created by the vLLM install script
NEMO_VENV="$BASE_DIR/nemo-venv"       # separate venv for NeMo ASR (avoids conflicts with vLLM)

# Load .env from same directory as this script — overrides HF_TOKEN above if set there
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    ENV_HF_TOKEN=$(grep -E '^HF_TOKEN=' "$ENV_FILE" | head -1 | cut -d '=' -f2- | tr -d '"' | tr -d "'")
    if [ -n "$ENV_HF_TOKEN" ]; then
        HF_TOKEN="$ENV_HF_TOKEN"
        echo "✅ HF_TOKEN loaded from .env"
    fi
fi

# If .env has no token but the script variable is set, write it into .env for next time
if [ -z "$ENV_HF_TOKEN" ] && [ -n "$HF_TOKEN" ]; then
    if grep -qE '^HF_TOKEN=' "$ENV_FILE" 2>/dev/null; then
        # Replace existing blank/empty entry
        sed -i "s|^HF_TOKEN=.*|HF_TOKEN=$HF_TOKEN|" "$ENV_FILE"
    else
        # Append to file (create it if it doesn't exist)
        echo "HF_TOKEN=$HF_TOKEN" >> "$ENV_FILE"
    fi
    echo "✅ HF_TOKEN saved to $ENV_FILE"
fi

if [ -z "$HF_TOKEN" ]; then
    echo "⚠️  HF_TOKEN is not set in .env or in this script — gated models will fail."
    echo "   Add HF_TOKEN=your_token_here to $ENV_FILE or set it at the top of this script."
fi

#--------------------------
sudo apt update
sudo apt install -y --no-install-recommends wget curl gnupg2 git libgl1 libglib2.0-0
sudo apt install -y jq
sudo apt install -y python3.12-dev python3-dev build-essential ninja-build

#-------- Docker / Containers ------------
# Check if docker is in the system's PATH
if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker is installed. Version: $(docker --version)"
else
    # BY DEFAULT DGX Spark has Docker installed!
    echo "❌ Docker is not installed."
    echo " You need docker first before running this. This will download a docker installer and run it for you. "
    wget -O "install_docker.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_docker.sh
    chmod u+x install_docker.sh
    ./install_docker.sh
fi


#--- SETUP vLLM on DGX Spark ---

curl -fsSL https://raw.githubusercontent.com/eelbaz/dgx-spark-vllm-setup/main/install.sh | bash

#------ Download & install models -----

# Auto-detect where the vLLM installer put its venv — try config path first, then known defaults
VENV_PIP=""
HF_CLI=""
for candidate in "$VLLM_VENV" "$HOME/vllm-install/.vllm" "/home/cgray/vllm-install/.vllm"; do
    if [ -x "$candidate/bin/pip" ]; then
        VENV_PIP="$candidate/bin/pip"
        HF_CLI="$candidate/bin/huggingface-cli"
        echo "✅ Using vLLM venv at $candidate"
        break
    fi
done

# If vLLM venv not found, create a dedicated downloader venv
if [ -z "$VENV_PIP" ]; then
    echo "⚠️  vLLM venv not found — creating dedicated downloader venv at $VLLM_VENV"
    python3 -m venv "$VLLM_VENV"
    VENV_PIP="$VLLM_VENV/bin/pip"
    HF_CLI="$VLLM_VENV/bin/huggingface-cli"
fi

# Install huggingface_hub + sentence-transformers into the detected venv
"$VENV_PIP" install -U "huggingface_hub[cli]" sentence-transformers

# NeMo goes in its own venv — its dependencies conflict with vLLM
python3 -m venv "$NEMO_VENV"
"$NEMO_VENV/bin/pip" install -U pip
"$NEMO_VENV/bin/pip" install "nemo_toolkit[asr]"

# Authenticate if token provided
if [ -n "$HF_TOKEN" ]; then
    "$HF_CLI" login --token "$HF_TOKEN" --add-to-git-credential
    HF_AUTH="--token $HF_TOKEN"
else
    echo "⚠️  HF_TOKEN is not set — gated models (nvidia/, some Qwen) will fail. Set it at the top of this script."
    HF_AUTH=""
fi

mkdir -p "$MODELS_DIR"

# Base download command — always write full files (no symlinks into HF cache)
HF_DL="$HF_CLI download --local-dir-use-symlinks False $HF_AUTH"


# 1. General / RAG generation / Financial research / reasoning
echo "--- Downloading Qwen/Qwen3.6-35B-A3B ---"
$HF_DL Qwen/Qwen3.6-35B-A3B \
    --local-dir "$MODELS_DIR/Qwen3.6-35B-A3B"

echo "--- Downloading nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-BF16 ---"
$HF_DL nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-BF16 \
    --local-dir "$MODELS_DIR/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-BF16"


# 2. Coding
echo "--- Downloading Qwen/Qwen3-Coder-30B-A3B-Instruct ---"
$HF_DL Qwen/Qwen3-Coder-30B-A3B-Instruct \
    --local-dir "$MODELS_DIR/Qwen3-Coder-30B-A3B-Instruct"


# 3. Financial research / reasoning (second opinion)
echo "--- Downloading deepseek-ai/DeepSeek-R1-Distill-Qwen-32B ---"
$HF_DL deepseek-ai/DeepSeek-R1-Distill-Qwen-32B \
    --local-dir "$MODELS_DIR/DeepSeek-R1-Distill-Qwen-32B"


# 4. Audio transcription (ASR — served via NeMo, not vLLM)
echo "--- Downloading nvidia/parakeet-tdt-0.6b-v3 ---"
$HF_DL nvidia/parakeet-tdt-0.6b-v3 \
    --local-dir "$MODELS_DIR/parakeet-tdt-0.6b-v3"

echo "--- Downloading nvidia/nemotron-speech-streaming-en-0.6b ---"
$HF_DL nvidia/nemotron-speech-streaming-en-0.6b \
    --local-dir "$MODELS_DIR/nemotron-speech-streaming-en-0.6b"


# 5. RAG embeddings (served via vLLM --task embedding, or sentence-transformers)
echo "--- Downloading BAAI/bge-m3 ---"
$HF_DL BAAI/bge-m3 \
    --local-dir "$MODELS_DIR/bge-m3"

echo "--- Downloading Qwen/Qwen3-Embedding-4B ---"
$HF_DL Qwen/Qwen3-Embedding-4B \
    --local-dir "$MODELS_DIR/Qwen3-Embedding-4B"


# 6. RAG reranking (served via sentence-transformers CrossEncoder or vLLM classify)
echo "--- Downloading BAAI/bge-reranker-v2-m3 ---"
$HF_DL BAAI/bge-reranker-v2-m3 \
    --local-dir "$MODELS_DIR/bge-reranker-v2-m3"


echo "✅ All models downloaded to $MODELS_DIR"


#----- Serve models with vLLM ------------------------------
# Uncomment and adjust the model you want to serve. Each needs its own port.

#--- Text generation / reasoning ---
if [ -f "$MODELS_DIR/Qwen3.6-35B-A3B/config.json" ]; then
    echo "--- Starting vLLM: Qwen3.6-35B-A3B on port 8000 ---"
    vllm serve "$MODELS_DIR/Qwen3.6-35B-A3B" \
        --host 0.0.0.0 --port 8000 \
        --dtype auto \
        --gpu-memory-utilization 0.85 \
        --max-model-len 32768 \
        --enable-prefix-caching \
        --trust-remote-code
else
    echo "⚠️  Qwen3.6-35B-A3B not found in $MODELS_DIR — skipping. Set HF_TOKEN and re-run to download it."
fi

# vllm serve "$MODELS_DIR/Qwen3-Coder-30B-A3B-Instruct" \
#   --host 0.0.0.0 --port 8001 \
#   --dtype auto \
#   --gpu-memory-utilization 0.85 \
#   --max-model-len 32768 \
#   --enable-prefix-caching \
#   --trust-remote-code

# vllm serve "$MODELS_DIR/DeepSeek-R1-Distill-Qwen-32B" \
#   --host 0.0.0.0 --port 8002 \
#   --dtype auto \
#   --gpu-memory-utilization 0.85 \
#   --max-model-len 32768 \
#   --enable-prefix-caching \
#   --trust-remote-code

#--- Embeddings ---
# vllm serve "$MODELS_DIR/bge-m3" \
#   --host 0.0.0.0 --port 8010 \
#   --task embedding \
#   --dtype auto \
#   --trust-remote-code

# vllm serve "$MODELS_DIR/Qwen3-Embedding-4B" \
#   --host 0.0.0.0 --port 8011 \
#   --task embedding \
#   --dtype auto \
#   --trust-remote-code

#--- Reranking ---
# vllm serve "$MODELS_DIR/bge-reranker-v2-m3" \
#   --host 0.0.0.0 --port 8020 \
#   --task classify \
#   --dtype auto \
#   --trust-remote-code

#--- Audio transcription (NeMo, not vLLM) ---
# python3 -c "
# import nemo.collections.asr as nemo_asr
# model = nemo_asr.models.EncDecRNNTBPEModel.restore_from('$MODELS_DIR/parakeet-tdt-0.6b-v3/model.nemo')
# print(model.transcribe(['your_audio.wav']))
# "




#--- Install OpenWebUI (Docker, connected to vLLM) ---
# OpenWebUI starts now and waits for vLLM — no need to block here.
# vLLM is not running yet; it starts after models are downloaded below.

echo "--- Starting OpenWebUI container ---"
# Remove existing container if it exists (re-run safe)
docker rm -f open-webui 2>/dev/null || true

# --network host: avoids Docker NAT overhead, direct access to vLLM on localhost:8000
# OPENAI_API_BASE_URL: points OpenWebUI at vLLM's OpenAI-compatible endpoint
# WEBUI_AUTH=false: skip login for local/private use (remove if you want auth)
docker run -d \
    --name open-webui \
    --network host \
    -v open-webui:/app/backend/data \
    -e OPENAI_API_BASE_URL=http://localhost:8000/v1 \
    -e OPENAI_API_KEY=sk-no-key-required \
    -e WEBUI_AUTH=false \
    --restart always \
    ghcr.io/open-webui/open-webui:main

# Wait for OpenWebUI itself to come up (not vLLM) — timeout after 3 minutes
echo "Waiting for OpenWebUI to be ready..."
OWUI_TIMEOUT=180
OWUI_ELAPSED=0
until curl -sf http://localhost:3000/health > /dev/null 2>&1; do
    if [ "$OWUI_ELAPSED" -ge "$OWUI_TIMEOUT" ]; then
        echo ""
        echo "⚠️  OpenWebUI did not become ready after ${OWUI_TIMEOUT}s — check logs with: docker logs open-webui"
        break
    fi
    printf "  [%ds] waiting...\n" "$OWUI_ELAPSED"
    sleep 5
    OWUI_ELAPSED=$((OWUI_ELAPSED + 5))
done
if [ "$OWUI_ELAPSED" -lt "$OWUI_TIMEOUT" ]; then
    echo "✅ OpenWebUI running at http://localhost:3000  (models will appear once vLLM starts)"
fi


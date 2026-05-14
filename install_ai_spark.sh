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


Version:  0.0.38
Last Updated:  5/14/2026

Update Yourself:
  wget --no-cache -O 'install_ai_spark.sh' 'https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_spark.sh' && chmod u+x install_ai_spark.sh


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
VENV_DIR=""
for candidate in "$VLLM_VENV" "$HOME/vllm-install/.vllm" "/home/cgray/vllm-install/.vllm"; do
    if [ -x "$candidate/bin/pip" ]; then
        VENV_PIP="$candidate/bin/pip"
        VENV_DIR="$candidate"
        echo "✅ Using vLLM venv at $candidate"
        break
    fi
done

# If vLLM venv not found, create a dedicated downloader venv
if [ -z "$VENV_PIP" ]; then
    echo "⚠️  vLLM venv not found — creating dedicated downloader venv at $VLLM_VENV"
    python3 -m venv "$VLLM_VENV"
    VENV_PIP="$VLLM_VENV/bin/pip"
    VENV_DIR="$VLLM_VENV"
fi

# Ensure vllm is actually installed — the eelbaz script can fail silently (e.g. Triton build error)
if ! "$VENV_DIR/bin/python" -c "import vllm" 2>/dev/null; then
    echo "⚠️  vllm not found in venv — installing via pip..."
    "$VENV_PIP" install -U vllm
    if "$VENV_DIR/bin/python" -c "import vllm" 2>/dev/null; then
        echo "✅ vllm installed successfully"
    else
        echo "❌ vllm install failed — check pip output above"
    fi
else
    echo "✅ vllm already installed: $("$VENV_DIR/bin/python" -c 'import vllm; print(vllm.__version__)')"
fi

# Install huggingface_hub + sentence-transformers into the detected venv
"$VENV_PIP" install -U "huggingface_hub[cli]" sentence-transformers

# Prefer new 'hf' CLI (replaces deprecated 'huggingface-cli')
if [ -x "$VENV_DIR/bin/hf" ]; then
    HF_CLI="$VENV_DIR/bin/hf"
    HF_LOGIN="$HF_CLI auth login"
else
    HF_CLI="$VENV_DIR/bin/huggingface-cli"
    HF_LOGIN="$HF_CLI login"
fi
echo "✅ Using HF CLI: $HF_CLI"

# NeMo goes in its own venv — its dependencies conflict with vLLM
python3 -m venv "$NEMO_VENV"
"$NEMO_VENV/bin/pip" install -U pip
"$NEMO_VENV/bin/pip" install "nemo_toolkit[asr]"

# Authenticate if token provided
if [ -n "$HF_TOKEN" ]; then
    $HF_LOGIN --token "$HF_TOKEN"
    HF_AUTH="--token $HF_TOKEN"
else
    echo "⚠️  HF_TOKEN is not set — gated models (nvidia/, some Qwen) will fail. Set it at the top of this script."
    HF_AUTH=""
fi

mkdir -p "$MODELS_DIR"

# Base download command — always write full files (no symlinks into HF cache)
HF_DL="$HF_CLI download $HF_AUTH"


# 1. General / RAG generation / Financial research / reasoning
echo "--- Downloading Qwen/Qwen3.6-35B-A3B ---"
$HF_DL Qwen/Qwen3.6-35B-A3B \
    --local-dir "$MODELS_DIR/Qwen3.6-35B-A3B"

echo "--- Downloading nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-BF16 ---"
$HF_DL nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-BF16 \
    --local-dir "$MODELS_DIR/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-BF16"

echo "--- Downloading nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4 ---"
$HF_DL nvidia/NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4 \
    --local-dir "$MODELS_DIR/NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4"


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
# Both models run in background (&) so the script continues.
# gpu-memory-utilization 0.70 for single-model use (30B BF16 weights alone need ~60 GiB).
# Raise to 0.85 (and remove the other) if you want to run only one at a time.
# OpenWebUI connects to port 8000 automatically. Add port 8001 manually:
#   OpenWebUI → Admin Settings → Connections → Add → http://localhost:8001/v1

VLLM_LOGS="$BASE_DIR/logs"
mkdir -p "$VLLM_LOGS"

# Locate the vllm binary — eelbaz uses uv which may not put it in the standard venv bin
VLLM_BIN=""
for candidate in \
    "$VENV_DIR/bin/vllm" \
    "$HOME/vllm-install/.vllm/bin/vllm" \
    "$HOME/.local/bin/vllm" \
    "/usr/local/bin/vllm" \
    "$(find "$HOME/vllm-install" -name vllm -type f 2>/dev/null | head -1)"; do
    if [ -x "$candidate" ]; then
        VLLM_BIN="$candidate"
        echo "✅ Found vllm binary at $VLLM_BIN"
        break
    fi
done

# Shell function so serve calls work whether we use the CLI or the Python module fallback
vllm_serve() {
    if [ -n "$VLLM_BIN" ]; then
        "$VLLM_BIN" serve "$@"
    else
        echo "⚠️  vllm not found — trying python module fallback"
        "$VENV_DIR/bin/python" -m vllm.entrypoints.openai.api_server "$@"
    fi
}

# Kill all vLLM processes, stop Docker, and wipe old logs for a clean start.
echo "--- Clean start: killing all vLLM processes and removing old logs ---"
docker stop open-webui 2>/dev/null || true
pkill -9 -f "vllm serve" 2>/dev/null || true
pkill -9 -f "vllm.entrypoints" 2>/dev/null || true
pkill -9 -f "VLLM::EngineCore" 2>/dev/null || true
pkill -9 -f "vllm.engine" 2>/dev/null || true
sleep 3
rm -f "$VLLM_LOGS"/vllm-*.log
echo "✅ Old vLLM processes killed and logs cleared"

# Enable TF32 for better matrix multiplication performance on Blackwell tensor cores
export TORCH_FLOAT32_MATMUL_PRECISION=high


#---- Coding -----
echo "\r\n \r\n --- Coding --- \r\n \r\n"
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


#--- Qwen3.6-35B-A3B  (port 8005) ---
if [ -f "$MODELS_DIR/Qwen3.6-35B-A3B/config.json" ]; then
    echo "--- Starting vLLM: Qwen3.6-35B-A3B on port 8005 ---"
    vllm_serve "$MODELS_DIR/Qwen3.6-35B-A3B" \
        --host 0.0.0.0 --port 8005 \
        --served-model-name "Qwen3.6-35B-A3B" \
        --dtype auto \
        --gpu-memory-utilization 0.85 \
        --max-model-len 32768 \
        --enable-prefix-caching \
        --trust-remote-code \
        >> "$VLLM_LOGS/vllm-8005.log" 2>&1 &
    echo "✅ Qwen3.6-35B-A3B starting on port 8005 (pid $!)"
    echo "   → Logs: tail -f $VLLM_LOGS/vllm-8005.log"
    echo "   → Status: curl -s http://localhost:8005/v1/models | jq ."
else
    echo "⚠️  Qwen3.6-35B-A3B not found in $MODELS_DIR — skipping."
fi



echo "\r\n \r\n --- General Purpose --- \r\n \r\n"
#--- Nemotron-3-Nano-Omni-30B-A3B-Reasoning-BF16  (port 8001 — add to OpenWebUI manually) ---
# if [ -f "$MODELS_DIR/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-BF16/config.json" ]; then
#     echo "--- Starting vLLM: Nemotron-3-Nano-Omni-30B-A3B-Reasoning-BF16 on port 8001 ---"
#     vllm_serve "$MODELS_DIR/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-BF16" \
#         --host 0.0.0.0 --port 8001 \
#         --served-model-name "Nemotron-3-Nano-Omni-30B-A3B" \
#         --dtype bfloat16 \
#         --gpu-memory-utilization 0.85 \
#         --max-model-len 32768 \
#         --enable-prefix-caching \
#         --trust-remote-code \
#         >> "$VLLM_LOGS/vllm-8001.log" 2>&1 &
#     echo "✅ Nemotron-3-Nano-Omni-30B-A3B starting on port 8001 (pid $!)"
#     echo "   → Logs: tail -f $VLLM_LOGS/vllm-8001.log"
#     echo "   → Status: curl -s http://localhost:8001/v1/models | jq ."
#     echo "   → Add to OpenWebUI: Admin Settings → Connections → http://localhost:8001/v1"
# else
#     echo "⚠️  Nemotron-3-Nano-Omni-30B-A3B-Reasoning-BF16 not found in $MODELS_DIR — skipping."
# fi

#--- NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4  (port 8002 — DGX Spark optimised, default model) ---
if [ -f "$MODELS_DIR/NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4/config.json" ]; then
    echo "--- Starting vLLM: NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4 on port 8006 ---"
    vllm_serve "$MODELS_DIR/NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4" \
        --host 0.0.0.0 --port 8006 \
        --served-model-name "Nemotron-3-Nano-30B-NVFP4" \
        --dtype auto \
        --quantization modelopt_fp4 \
        --gpu-memory-utilization 0.85 \
        --max-model-len 32768 \
        --enable-prefix-caching \
        --trust-remote-code \
        >> "$VLLM_LOGS/vllm-8006.log" 2>&1 &
    echo "✅ Nemotron-3-Nano-30B-NVFP4 starting on port 8006 (pid $!)"
    echo "   → Logs: tail -f $VLLM_LOGS/vllm-8006.log"
    echo "   → Status: curl -s http://localhost:8006/v1/models | jq ."
    echo "   → Add to OpenWebUI: Admin Settings → Connections → http://localhost:8006/v1"
else
    echo "⚠️  NVIDIA-Nemotron-3-Nano-30B-A3B-NVFP4 not found in $MODELS_DIR — skipping."
fi


#--- Qwen3-Embedding-4B  (port 8010) ---
if [ -f "$MODELS_DIR/Qwen3-Embedding-4B/config.json" ]; then
    echo "--- Starting vLLM: Qwen3-Embedding-4B on port 8010 ---"
    vllm_serve "$MODELS_DIR/Qwen3-Embedding-4B" \
        --host 0.0.0.0 --port 8010 \
        --served-model-name "Qwen3-Embedding-4B" \
        --task embedding \
        --dtype auto \
        --gpu-memory-utilization 0.50 \
        --trust-remote-code \
        >> "$VLLM_LOGS/vllm-8010.log" 2>&1 &
    echo "✅ Qwen3-Embedding-4B starting on port 8010 (pid $!)"
    echo "   → Logs: tail -f $VLLM_LOGS/vllm-8010.log"
    echo "   → Status: curl -s http://localhost:8010/v1/models | jq ."
else
    echo "⚠️  Qwen3-Embedding-4B not found in $MODELS_DIR — skipping."
fi

#--- bge-reranker-v2-m3  (port 8020) ---
if [ -f "$MODELS_DIR/bge-reranker-v2-m3/config.json" ]; then
    echo "--- Starting vLLM: bge-reranker-v2-m3 on port 8020 ---"
    vllm_serve "$MODELS_DIR/bge-reranker-v2-m3" \
        --host 0.0.0.0 --port 8020 \
        --served-model-name "bge-reranker-v2-m3" \
        --task classify \
        --dtype auto \
        --gpu-memory-utilization 0.50 \
        --trust-remote-code \
        >> "$VLLM_LOGS/vllm-8020.log" 2>&1 &
    echo "✅ bge-reranker-v2-m3 starting on port 8020 (pid $!)"
    echo "   → Logs: tail -f $VLLM_LOGS/vllm-8020.log"
    echo "   → Status: curl -s http://localhost:8020/v1/models | jq ."
else
    echo "⚠️  bge-reranker-v2-m3 not found in $MODELS_DIR — skipping."
fi


#--- Audio transcription (NeMo, not vLLM) ---
# python3 -c "
# import nemo.collections.asr as nemo_asr
# model = nemo_asr.models.EncDecRNNTBPEModel.restore_from('$MODELS_DIR/parakeet-tdt-0.6b-v3/model.nemo')
# print(model.transcribe(['your_audio.wav']))
# "


#---------------------------------------------------------------------------------------------------------------
#--- Start OpenWebUI (Docker, connected to all vLLM instances) ---
# --network host: direct access to all vLLM ports without Docker NAT
# OPENAI_API_BASE_URLS: semicolon-separated list of all active vLLM endpoints
# OPENAI_API_KEYS: matching semicolon-separated keys (one per endpoint)

echo "--- Starting OpenWebUI container ---"
docker rm -f open-webui 2>/dev/null || true

docker run -d \
    --name open-webui \
    --network host \
    -v open-webui:/app/backend/data \
    -e PORT=3000 \
    -e OPENAI_API_BASE_URLS="http://localhost:8006/v1;http://localhost:8005/v1;http://localhost:8010/v1;http://localhost:8020/v1" \
    -e OPENAI_API_KEYS="sk-no-key-required;sk-no-key-required;sk-no-key-required;sk-no-key-required" \
    -e WEBUI_AUTH=false \
    --restart always \
    ghcr.io/open-webui/open-webui:main

echo "Waiting for OpenWebUI to be ready..."
OWUI_TIMEOUT=300
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
    echo "✅ OpenWebUI ready at http://localhost:3000"
    echo "   Models available:"
    echo "   → Nemotron-3-Nano-30B-NVFP4    port 8006  (default)"
    echo "   → Qwen3.6-35B-A3B              port 8005"
    echo "   → Qwen3-Embedding-4B           port 8010"
    echo "   → bge-reranker-v2-m3           port 8020"
fi




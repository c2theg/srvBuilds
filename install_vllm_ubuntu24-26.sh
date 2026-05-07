#!/usr/bin/env bash
# =============================================================================
#  install_vllm.sh — vLLM installer for Ubuntu 24.04 / 26.04+
#  Usage: sudo bash install_vllm.sh [--no-gpu] [--python 3.13] [--venv /opt/vllm]
# =============================================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()     { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()   { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
die()    { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }
banner() { echo -e "\n${BOLD}${CYAN}=== $* ===${RESET}\n"; }

# ── Defaults ─────────────────────────────────────────────────────────────────
PYTHON_VERSION=""      # auto-detected unless --python is passed
INSTALL_GPU=true
VENV_DIR="/opt/vllm"
VLLM_EXTRA=""          # e.g. "[audio,video]"

MIN_MAJOR=3
MIN_MINOR=12           # minimum acceptable Python minor version
FALLBACK_MINOR=13      # install this minor if nothing qualifies on the system

# ── Arg parsing ───────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-gpu)  INSTALL_GPU=false ;;
    --python)  PYTHON_VERSION="$2"; shift ;;
    --venv)    VENV_DIR="$2"; shift ;;
    --extra)   VLLM_EXTRA="$2"; shift ;;
    -h|--help)
      echo "Usage: sudo bash $0 [--no-gpu] [--python 3.13] [--venv /opt/vllm] [--extra '[audio]']"
      exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
  shift
done

# ── Preflight ─────────────────────────────────────────────────────────────────
banner "vLLM Installer — Ubuntu 24.04 / 26.04+"

[[ $EUID -ne 0 ]] && die "Run this script with sudo or as root."

# Load /etc/os-release (sets VERSION_ID, VERSION_CODENAME, ID, etc.)
. /etc/os-release
[[ "$ID" != "ubuntu" ]]          && die "This script targets Ubuntu only."
[[ "${VERSION_ID%%.*}" -lt 24 ]] && die "Ubuntu 24.04+ required (detected $VERSION_ID)."
ok "OS: Ubuntu $VERSION_ID (${VERSION_CODENAME:-unknown})"

# Compact tag used by NVIDIA repos: strip the dot → "2404", "2604", etc.
UBUNTU_TAG="ubuntu$(echo "$VERSION_ID" | tr -d '.')"

# ── Base system packages ───────────────────────────────────────────────────────
banner "Installing base system dependencies"

apt-get update -qq
apt-get install -y --no-install-recommends \
  software-properties-common \
  build-essential \
  curl \
  git \
  wget \
  ca-certificates \
  lsb-release \
  python3-pip
ok "Base packages installed"

# ── Helpers ───────────────────────────────────────────────────────────────────

# py_gte A B → returns 0 (true) if major.minor string A >= B
py_gte() {
  local a_maj a_min b_maj b_min
  IFS='.' read -r a_maj a_min <<< "$1"
  IFS='.' read -r b_maj b_min <<< "$2"
  [[ "$a_maj" -gt "$b_maj" ]] && return 0
  [[ "$a_maj" -eq "$b_maj" && "$a_min" -ge "$b_min" ]] && return 0
  return 1
}

# Try to install python<ver> from the deadsnakes PPA.
# Returns 0 on success, 1 if PPA is unavailable or package is absent.
install_python_deadsnakes() {
  local pyver="$1"
  log "Trying deadsnakes PPA for python${pyver}..."

  if ! add-apt-repository -y ppa:deadsnakes/ppa 2>/dev/null; then
    warn "Could not add deadsnakes PPA (network failure or unsupported distro)."
    return 1
  fi

  apt-get update -qq

  if ! apt-cache show "python${pyver}" &>/dev/null; then
    warn "python${pyver} not found in deadsnakes for Ubuntu ${VERSION_ID}."
    return 1
  fi

  apt-get install -y --no-install-recommends \
    "python${pyver}" \
    "python${pyver}-dev" \
    "python${pyver}-venv"
  ok "python${pyver} installed via deadsnakes PPA."
  return 0
}

# Compile and install python<ver> via pyenv.
# Used as a fallback when deadsnakes doesn't carry a given release yet.
install_python_pyenv() {
  local pyver="$1"
  local pyenv_root="/opt/pyenv"
  warn "deadsnakes unavailable — falling back to pyenv (compiles from source)."

  # Build-time dependencies (covers both 24.04 and 26.04)
  apt-get install -y --no-install-recommends \
    libssl-dev libffi-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev \
    libxmlsec1-dev liblzma-dev

  if [[ ! -d "$pyenv_root" ]]; then
    git clone --depth=1 https://github.com/pyenv/pyenv.git "$pyenv_root"
  else
    log "pyenv already present at ${pyenv_root} — pulling latest..."
    git -C "$pyenv_root" pull --quiet
  fi

  export PYENV_ROOT="$pyenv_root"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"

  # Find the latest patch release for the requested major.minor
  local latest
  latest=$(pyenv install --list \
    | grep -E "^\s+${pyver}\.[0-9]+$" \
    | tail -1 \
    | tr -d ' ')
  [[ -z "$latest" ]] \
    && die "pyenv has no entry for python${pyver} — run 'pyenv install --list' to check."

  log "Building python ${latest} via pyenv (this may take a few minutes)..."
  pyenv install --skip-existing "$latest"
  pyenv global "$latest"

  # Expose as a versioned binary so the rest of the script finds it
  ln -sf "${PYENV_ROOT}/versions/${latest}/bin/python3" "/usr/local/bin/python${pyver}"
  ok "python${pyver} (${latest}) installed via pyenv."
}

# Master entry point: check for existing install, then deadsnakes, then pyenv.
ensure_python() {
  local pyver="$1"
  if command -v "python${pyver}" &>/dev/null; then
    ok "python${pyver} already installed ($(python${pyver} --version)) — skipping."
    return 0
  fi
  install_python_deadsnakes "$pyver" || install_python_pyenv "$pyver"
}

# ── Python detection / installation ───────────────────────────────────────────
banner "Resolving Python interpreter"

if [[ -n "$PYTHON_VERSION" ]]; then
  # ── User pinned a version with --python ──────────────────────────────────
  log "Python version pinned via --python: ${PYTHON_VERSION}"
  py_gte "$PYTHON_VERSION" "${MIN_MAJOR}.${MIN_MINOR}" \
    || die "--python ${PYTHON_VERSION} is below the minimum required ${MIN_MAJOR}.${MIN_MINOR}."
  ensure_python "$PYTHON_VERSION"
else
  # ── Auto-detect: find highest python3.x >= 3.12 already on the system ────
  log "Scanning for python${MIN_MAJOR}.${MIN_MINOR}+ on this system..."
  BEST_VER=""

  # compgen may not work in non-interactive shells; fall back to globbing.
  CANDIDATES=$(compgen -c python3. 2>/dev/null \
    || { ls /usr/bin/python3.* /usr/local/bin/python3.* 2>/dev/null \
         | xargs -n1 basename; } \
    || true)

  for bin in $(echo "$CANDIDATES" | sort -uV); do
    ver="${bin#python}"
    [[ "$ver" =~ ^[0-9]+\.[0-9]+$ ]] || continue
    command -v "$bin" &>/dev/null     || continue
    if py_gte "$ver" "${MIN_MAJOR}.${MIN_MINOR}"; then
      if [[ -z "$BEST_VER" ]] || py_gte "$ver" "$BEST_VER"; then
        BEST_VER="$ver"
      fi
    fi
  done

  if [[ -n "$BEST_VER" ]]; then
    PYTHON_VERSION="$BEST_VER"
    ok "Found python${PYTHON_VERSION} — no installation needed."
  else
    PYTHON_VERSION="${MIN_MAJOR}.${FALLBACK_MINOR}"
    warn "No python>=${MIN_MAJOR}.${MIN_MINOR} found — installing python${PYTHON_VERSION}."
    ensure_python "$PYTHON_VERSION"
  fi
fi

# Ensure -dev and -venv sub-packages exist for the chosen version.
# These are often absent in minimal images even when the interpreter is present.
log "Ensuring python${PYTHON_VERSION}-dev and python${PYTHON_VERSION}-venv..."
apt-get install -y --no-install-recommends \
  "python${PYTHON_VERSION}-dev" \
  "python${PYTHON_VERSION}-venv" 2>/dev/null \
  || warn "apt sub-packages unavailable — likely bundled inside a pyenv build (continuing)."

log "Selected interpreter: python${PYTHON_VERSION} ($(python${PYTHON_VERSION} --version))"

# ── GPU / CUDA setup ──────────────────────────────────────────────────────────
if $INSTALL_GPU; then
  banner "Detecting GPU / CUDA"

  if command -v nvidia-smi &>/dev/null; then
    CUDA_VER=$(nvidia-smi | awk '/CUDA Version/{print $NF}')
    ok "NVIDIA driver already present — CUDA ${CUDA_VER}"
  else
    warn "nvidia-smi not found — attempting NVIDIA CUDA repo install."

    CUDA_KEYRING_DEB="cuda-keyring_1.1-1_all.deb"
    CUDA_KEYRING_URL="https://developer.download.nvidia.com/compute/cuda/repos/${UBUNTU_TAG}/x86_64/${CUDA_KEYRING_DEB}"
    log "Probing NVIDIA repo for ${UBUNTU_TAG}..."

    if curl --silent --head --fail --max-time 10 "$CUDA_KEYRING_URL" &>/dev/null; then
      # ── Official NVIDIA repo exists for this Ubuntu release ───────────────
      wget -q "$CUDA_KEYRING_URL" -O "/tmp/${CUDA_KEYRING_DEB}"
      dpkg -i "/tmp/${CUDA_KEYRING_DEB}"
      apt-get update -qq

      # 'cuda-drivers' is NVIDIA's meta-package — it always pulls the correct
      # driver for the installed CUDA version, so no hardcoded versions needed.
      apt-get install -y --no-install-recommends \
        cuda-toolkit \
        cuda-drivers
      ok "CUDA toolkit + drivers installed via NVIDIA repo — a reboot is likely required."
    else
      # ── NVIDIA hasn't published a repo for this Ubuntu release yet ────────
      warn "NVIDIA CUDA repo not yet available for Ubuntu ${VERSION_ID} (${UBUNTU_TAG})."
      warn "Trying ubuntu-drivers as a fallback..."

      if apt-cache show ubuntu-drivers-common &>/dev/null 2>&1; then
        apt-get install -y --no-install-recommends ubuntu-drivers-common
        ubuntu-drivers install --gpgpu \
          && ok "GPU driver installed via ubuntu-drivers." \
          || warn "ubuntu-drivers install also failed."
      else
        warn "ubuntu-drivers-common not available on this release."
      fi

      warn "──────────────────────────────────────────────────────────────────"
      warn " Action required: manually install CUDA for Ubuntu ${VERSION_ID}"
      warn "   https://developer.nvidia.com/cuda-downloads"
      warn " Re-run this script afterwards — it will skip the driver step."
      warn "──────────────────────────────────────────────────────────────────"
    fi
  fi
else
  warn "--no-gpu set — skipping CUDA/driver installation (CPU-only mode)."
fi

# ── Python venv ───────────────────────────────────────────────────────────────
banner "Creating Python ${PYTHON_VERSION} virtual environment → ${VENV_DIR}"

"python${PYTHON_VERSION}" -m venv "$VENV_DIR"
# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

pip install --upgrade pip wheel setuptools -q
ok "Virtualenv ready: ${VENV_DIR}"

# ── Install vLLM ─────────────────────────────────────────────────────────────
banner "Installing vLLM${VLLM_EXTRA:+ (extras: $VLLM_EXTRA)}"

if $INSTALL_GPU; then
  # Standard PyPI wheel — bundles CUDA 12.x runtime libraries
  pip install "vllm${VLLM_EXTRA}" -q
else
  # CPU-only build via PyTorch CPU wheel index
  pip install \
    "vllm${VLLM_EXTRA}" \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    -q
fi
ok "vLLM installed"

# ── Verify ────────────────────────────────────────────────────────────────────
banner "Verifying installation"

VLLM_VER=$(pip show vllm | awk '/^Version/{print $2}')
ok "vLLM version: ${VLLM_VER}"
python -c "import vllm; print('Import OK')" && ok "Python import successful"

# ── Convenience wrapper ───────────────────────────────────────────────────────
banner "Installing system-wide 'vllm' wrapper"

cat > /usr/local/bin/vllm <<WRAPPER
#!/usr/bin/env bash
source "${VENV_DIR}/bin/activate"
exec python -m vllm "\$@"
WRAPPER
chmod +x /usr/local/bin/vllm
ok "Wrapper written to /usr/local/bin/vllm"

# ── Systemd service template ──────────────────────────────────────────────────
banner "Writing optional systemd service template"

SERVICE_FILE="/etc/systemd/system/vllm.service"
cat > "$SERVICE_FILE" <<SERVICE
[Unit]
Description=vLLM OpenAI-compatible API server
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
Environment="HOME=/tmp"
ExecStart=${VENV_DIR}/bin/python -m vllm.entrypoints.openai.api_server \\
    --model meta-llama/Llama-3.1-8B-Instruct \\
    --host 0.0.0.0 \\
    --port 8000
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE
ok "Service template: ${SERVICE_FILE}"
warn "Edit ExecStart in ${SERVICE_FILE} with your model path before enabling."

# ── Done ──────────────────────────────────────────────────────────────────────
banner "Installation Complete"
echo -e "
  ${BOLD}Quick start:${RESET}
    source ${VENV_DIR}/bin/activate
    python -m vllm.entrypoints.openai.api_server \\
        --model meta-llama/Llama-3.1-8B-Instruct --port 8000

  ${BOLD}Or via wrapper:${RESET}
    vllm serve meta-llama/Llama-3.1-8B-Instruct --port 8000

  ${BOLD}Enable as a service:${RESET}
    sudo systemctl daemon-reload
    sudo systemctl enable --now vllm

  ${BOLD}Virtualenv path:${RESET}  ${VENV_DIR}
  ${BOLD}Python version:${RESET}   ${PYTHON_VERSION}
  ${BOLD}vLLM version:${RESET}     ${VLLM_VER}
  ${BOLD}Ubuntu:${RESET}           ${VERSION_ID} (${UBUNTU_TAG})
"

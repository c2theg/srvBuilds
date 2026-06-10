#!/bin/bash
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
|   --|   |  _| |_ -|  _| . | . |   | -_|  _|  | | | |  |  |  |    _| .'| | |   |
|_____|_|_|_| |_|___|_| |___|  _|_|_|___|_|    |_|_|_|_____|  |_____|_| |__,|_  |
                            |_|                                             |___|


Version:  0.2.4
Last Updated:  6/10/2026

# https://ollama.com/search

"

#-- Update yourself! --
# TODO: Re-enable once v0.2.2 changes are pushed to GitHub.
#       These wget lines overwrite this script with the GitHub version on every run,
#       which reverts all local changes before they can execute.
#wget -O "install_ai.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai.sh && chmod u+x install_ai.sh
wget -O "install_ai_containers.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_containers.sh && chmod u+x install_ai_containers.sh
wget -O "update_ai_models.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/update_ai_models.sh && chmod u+x update_ai_models.sh

#==============================================================================

detect_os() {
    if [ ! -f /etc/os-release ]; then
        echo "ERROR: Cannot detect OS; /etc/os-release not found." >&2
        exit 1
    fi
    . /etc/os-release
    OS_ID="${ID:-linux}"
    OS_VERSION="${VERSION_ID:-unknown}"
    OS_CODENAME="${VERSION_CODENAME:-unknown}"

    # Validate values from /etc/os-release before using in URLs
    if ! echo "$OS_VERSION" | grep -qE '^[0-9]+\.[0-9]+$'; then
        echo "ERROR: Unexpected OS_VERSION '$OS_VERSION' from /etc/os-release" >&2; exit 1
    fi
    if ! echo "$OS_CODENAME" | grep -qE '^[a-z]+$'; then
        echo "ERROR: Unexpected OS_CODENAME '$OS_CODENAME' from /etc/os-release" >&2; exit 1
    fi

    case "$OS_VERSION" in
        22.04) CUDA_DISTRO="ubuntu2204" ;;
        24.04) CUDA_DISTRO="ubuntu2404" ;;
        26.04) CUDA_DISTRO="ubuntu2604" ;;
        *)
            CUDA_DISTRO="ubuntu$(echo "$OS_VERSION" | tr -d '.')"
            echo "Warning: Ubuntu $OS_VERSION is not an officially tested version."
            ;;
    esac

    echo "OS: $OS_ID $OS_VERSION ($OS_CODENAME) — CUDA target: $CUDA_DISTRO"
}

detect_gpu() {
    echo "Scanning PCI devices for GPU..."
    GPU_INFO=$(lspci -k 2>/dev/null | grep -EA3 'VGA|3D|Display' || true)
    echo "$GPU_INFO"

    if echo "$GPU_INFO" | grep -qi "nvidia"; then
        GPU_TYPE="nvidia"
    elif echo "$GPU_INFO" | grep -qi "amd\|radeon"; then
        GPU_TYPE="amd"
    else
        GPU_TYPE="cpu"
    fi
    echo "GPU type detected: $GPU_TYPE"
}

detect_arch() {
    case "$(uname -m)" in
        x86_64)  OLLAMA_ARCH="amd64" ;;
        aarch64) OLLAMA_ARCH="arm64" ;;
        *)       OLLAMA_ARCH="amd64" ; echo "Warning: Unknown arch $(uname -m), defaulting to amd64" ;;
    esac
    echo "Architecture: $(uname -m) → Ollama arch: $OLLAMA_ARCH"
}

cleanup_broken_amdgpu() {
    # If amdgpu-dkms is in any installed/half-installed state, dpkg will try to
    # configure it on EVERY apt-get call, triggering the DKMS build that fails
    # against kernel 7.x. Must run before the first apt-get install.
    if ! dpkg -l amdgpu-dkms 2>/dev/null | grep -qE '^[ih]'; then
        return 0
    fi
    echo "Removing broken amdgpu-dkms before apt operations..."
    # Pull it out of the DKMS tree first so the postinst script has nothing to build
    sudo dkms remove --all amdgpu 2>/dev/null || true
    sudo rm -rf /var/lib/dkms/amdgpu 2>/dev/null || true
    # Force-purge even if postinst would fail
    sudo dpkg --force-remove-reinstreq --purge amdgpu-dkms amdgpu amdgpu-pro 2>/dev/null || true
    sudo apt-get autoremove -y 2>/dev/null || true
    sudo apt-get install -f -y 2>/dev/null || true
    echo "amdgpu-dkms removed. Kernel 7.x ships amdgpu in-tree — DKMS not needed."
}

install_oem_kernel() {
    case "$OS_VERSION" in
        22.04) OEM_PKG="linux-oem-22.04d" ;;
        24.04) OEM_PKG="linux-oem-24.04b"  ;;
        26.04) OEM_PKG="linux-oem-26.04"   ;;
        *)     OEM_PKG=""                   ;;
    esac
    if [ -n "$OEM_PKG" ] && apt-cache show "$OEM_PKG" &>/dev/null; then
        echo "Installing OEM kernel: $OEM_PKG"
        sudo apt-get install -y "$OEM_PKG"
    else
        echo "OEM kernel package not available for Ubuntu $OS_VERSION, skipping."
    fi
}

install_nvidia() {
    echo ""
    echo "==== Installing NVIDIA CUDA + Container Toolkit for Ubuntu $OS_VERSION ===="
    echo "    lspci | grep -i nvidia"
    echo "    https://developer.nvidia.com/cuda-downloads"
    echo ""

    # Blacklist nouveau if loaded to prevent driver conflicts
    if lsmod | grep -q nouveau 2>/dev/null; then
        echo "Blacklisting nouveau driver..."
        echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
        echo "options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
        sudo update-initramfs -u
        echo "NOTE: A reboot may be required after this script completes."
    fi

    # CUDA network repository keyring (avoids the 3.9 GB local installer download)
    echo "Adding CUDA repository for $CUDA_DISTRO..."
    local _kring
    _kring=$(mktemp --suffix=.deb)
    wget -q -O "$_kring" \
        "https://developer.download.nvidia.com/compute/cuda/repos/${CUDA_DISTRO}/x86_64/cuda-keyring_1.1-1_all.deb"
    sudo dpkg -i "$_kring"
    rm -f "$_kring"
    sudo apt-get update

    # Auto-install the best driver for this GPU + OS version
    sudo apt-get install -y ubuntu-drivers-common
    sudo ubuntu-drivers autoinstall

    # CUDA toolkit (latest available in repo for this OS)
    sudo apt-get install -y cuda-toolkit

    # NVIDIA Container Toolkit for Docker GPU passthrough
    echo "Adding nvidia-container-toolkit repository..."
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
        | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -sL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
        | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
        | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt-get update
    sudo apt-get install -y \
        nvidia-container-toolkit \
        nvidia-container-toolkit-base \
        libnvidia-container-tools \
        libnvidia-container1

    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker

    echo ""
    echo "NVIDIA setup complete. Run 'nvidia-smi' to verify."
    echo "If nvidia-smi fails, reboot then re-run 'nvidia-smi'."
    echo ""
    echo "Proxmox / IOMMU notes:"
    echo "  Add to /etc/default/grub for Intel: intel_iommu=on"
    echo "  Add to /etc/default/grub for AMD:   amd_iommu=on"
    echo "  Then: update-grub && reboot"
    echo "  Verify: lspci -nnk | grep -A3 -i nvidia"
}

install_amd() {
    echo ""
    echo "==== Installing AMD ROCm for Ubuntu $OS_VERSION ($OS_CODENAME) ===="

    if [ "$OS_VERSION" = "26.04" ]; then
        # Ubuntu 26.04: kernel 7.x ships amdgpu in-tree; amdgpu-install has no
        # resolute packages and its DKMS module cannot compile against kernel 7.x.
        # Add the ROCm apt repo directly and install user-space only — no DKMS.
        echo "Using direct ROCm apt repo for Ubuntu 26.04 (no amdgpu-install/DKMS)..."
        sudo mkdir -p /etc/apt/keyrings
        curl -sSf https://repo.radeon.com/rocm/rocm.gpg.key \
            | sudo gpg --dearmor -o /etc/apt/keyrings/rocm.gpg
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/6.4.1 noble main" \
            | sudo tee /etc/apt/sources.list.d/rocm.list
        printf 'Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600\n' \
            | sudo tee /etc/apt/preferences.d/rocm-pin-600
        sudo apt-get update
        sudo apt-get install -y rocm-hip-runtime rocminfo rocm-smi-lib libdrm-amdgpu1
    else
        # Ubuntu 22.04 / 24.04: use amdgpu-install (handles DKMS + ROCm user-space)
        ROCM_VERSION="6.4.1"
        ROCM_PKG_VER="6.4.60401-1"
        AMD_DEB="amdgpu-install_${ROCM_PKG_VER}_all.deb"
        AMD_URL="https://repo.radeon.com/amdgpu-install/${ROCM_VERSION}/ubuntu/${OS_CODENAME}/${AMD_DEB}"

        echo "Downloading $AMD_DEB for $OS_CODENAME..."
        local _amd_tmp
        _amd_tmp=$(mktemp --suffix=.deb)
        wget -q -O "$_amd_tmp" "$AMD_URL" || {
            rm -f "$_amd_tmp"
            echo "ERROR: Could not download AMD GPU installer from: $AMD_URL"
            echo "Check https://repo.radeon.com/amdgpu-install/ for the correct version/codename."
            exit 1
        }
        sudo apt install -y "$_amd_tmp"
        rm -f "$_amd_tmp"
        sudo apt-get update
        sudo amdgpu-install -y --usecase=workstation,rocm
        sudo apt install -y libdrm-amdgpu1 libhsa-runtime64-1 libhsakmt1 rocminfo
    fi

    echo ""
    echo "AMD ROCm setup complete. Run 'rocminfo' to verify."
    echo ""
    echo "Proxmox / IOMMU notes:"
    echo "  Add to /etc/default/grub: amd_iommu=on iommu=pt"
    echo "  Then: update-grub && reboot"
    echo "  Verify: lspci -nn | grep -i amd"
}

_setup_ollama_service() {
    id -u ollama &>/dev/null || sudo useradd -r -s /bin/false -U -m -d /usr/share/ollama ollama
    sudo usermod -a -G ollama "$(whoami)" 2>/dev/null || true

    sudo tee /etc/systemd/system/ollama.service > /dev/null << 'EOF'
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=default.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ollama
    sudo systemctl start ollama || true
}

install_ollama() {
    local gpu_type="$1"
    echo ""
    echo "==== Installing Ollama ($gpu_type / $OLLAMA_ARCH) ===="

    if [ "$gpu_type" = "amd" ] && [ "$OLLAMA_ARCH" = "amd64" ]; then
        # AMD ROCm requires a specific binary; only available for x86_64
        local tgz="ollama-linux-amd64-rocm.tgz"
        local _tmp_tgz
        _tmp_tgz=$(mktemp --suffix=.tgz)
        echo "Downloading ROCm-enabled Ollama binary..."
        curl -fL "https://ollama.com/download/${tgz}" -o "$_tmp_tgz"
        sudo tar -C /usr -xzf "$_tmp_tgz"
        rm -f "$_tmp_tgz"
        _setup_ollama_service
    else
        # Download install.sh first so it can be inspected before execution
        local _tmp_install
        _tmp_install=$(mktemp --suffix=.sh)
        curl -fsSL https://ollama.com/install.sh -o "$_tmp_install"
        sh "$_tmp_install"
        rm -f "$_tmp_install"
    fi

    echo "Ollama installed. Service status:"
    sudo systemctl status ollama --no-pager -l || true
}

#==============================================================================
# MAIN
#==============================================================================

detect_os
detect_arch

# On Ubuntu 26.04, amdgpu-dkms from ROCm 6.4.x cannot build against kernel 7.x.
# If stuck in a half-installed state it will fail on EVERY apt-get call.
# Purge it before any apt operation.
[ "$OS_VERSION" = "26.04" ] && cleanup_broken_amdgpu

# Base dependencies (pciutils required before GPU detection)
echo "Installing base dependencies..."
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    wget curl gnupg2 git \
    libgl1 libglib2.0-0 \
    pciutils jq

install_oem_kernel

# Docker check / install
if command -v docker >/dev/null 2>&1; then
    echo "Docker installed: $(docker --version)"
else
    echo "Docker not found. Installing Docker..."
    _tmp_docker=$(mktemp --suffix=.sh)
    wget -O "$_tmp_docker" \
        https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_docker.sh
    chmod u+x "$_tmp_docker"
    "$_tmp_docker"
    rm -f "$_tmp_docker"
fi

# Ollama model storage — 755 not 777; ollama service owns it
sudo mkdir -p /usr/share/ollama/models
id -u ollama &>/dev/null && sudo chown -R ollama:ollama /usr/share/ollama/models 2>/dev/null || true
sudo chmod -R 755 /usr/share/ollama/models

detect_gpu

# GPU driver installation (Ollama installed after so NVIDIA CUDA is already present)
case "$GPU_TYPE" in
    nvidia) install_nvidia ;;
    amd)    install_amd    ;;
esac

# Ollama install — must run after GPU drivers so CUDA/ROCm is already present
install_ollama "$GPU_TYPE"


echo "

Download & Install Containers (Ollama, Open-WebUI, etc.)

"
sleep 5

echo "

Update Ollama


"
curl -fsSL https://ollama.com/install.sh | sh


echo "

Install Containers (Ollama, Open-WebUI, etc.)


"
#sudo ./install_ai_containers.sh


#---- AI MODELS ----
# https://ollama.com/search

echo "

Download - Install or Update - AI Models


"
./update_ai_models.sh

#wget -O "install_ai_models.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_models.sh && chmod +x install_ai_models.sh && ./install_ai_models.sh

sleep 10

echo "

---- List all Models ----

"

curl http://localhost:11434/api/tags | jq .

echo "

------------------------------
Hello World - Ollama!
------------------------------

"

curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Why is the sky blue?",
  "stream": false
}'

# curl http://localhost:11434/api/generate -d '{
#   "model": "llama3.2-vision",
#   "prompt": "Generate me a picture of a beautifly sunset and save the picture locally",
#   "stream": false
# }'


#---- Python 3 ----
# echo "

# Installing Python 3 for AI Developmemt...


# "
# if [ ! -f "install_python3.sh" ]; then
#     wget -O "install_python3.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_python3.sh && chmod u+x install_python3.sh
# fi

# if [ ! -f "install_ai_python3_venv.sh" ]; then
#     wget -O "install_ai_python3_venv.sh" https://raw.githubusercontent.com/c2theg/srvBuilds/refs/heads/master/install_ai_python3_venv.sh && chmod u+x install_ai_python3_venv.sh
#     ./install_ai_python3_venv.sh
# fi

#--- end Python 3 ----

echo "

==============================
        Ollama Cloud

   https://ollama.com/cloud
==============================

If you want to run models in ollama cloud you must setup an account and sign in. Use the following command to generate an API token with ollama.com and a account

Command:
    ollama signin



ALL DONE!


Access the webui at http://localhost:3000
Ollama API at: http://localhost:11434


"

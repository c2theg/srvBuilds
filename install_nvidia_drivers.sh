#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# install_nvidia_drivers.sh
#
# Installs the latest NVIDIA drivers for Ubuntu 24.04 + RTX 5080 (Blackwell).
# Fixes "Driver/library version mismatch" by fully purging old drivers first
# and installing a clean copy from NVIDIA's official CUDA repository.
#
# Usage:
#   sudo bash install_nvidia_drivers.sh
#
# The system will need a reboot after completion.
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ── Root check ────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo "[error] This script must be run as root: sudo bash $0"
  exit 1
fi

UBUNTU_CODENAME="noble"   # Ubuntu 24.04
ARCH="x86_64"
CUDA_KEYRING_URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/${ARCH}/cuda-keyring_1.1-1_all.deb"

echo "══════════════════════════════════════════════════"
echo "  NVIDIA Driver Installer — Ubuntu 24.04 / RTX 5080"
echo "══════════════════════════════════════════════════"
echo ""

# ── Step 1: Unload current (mismatched) kernel module ─────────────────────────
echo "[1/7] Unloading NVIDIA kernel modules..."
rmmod nvidia_uvm    2>/dev/null || true
rmmod nvidia_drm    2>/dev/null || true
rmmod nvidia_modeset 2>/dev/null || true
rmmod nvidia        2>/dev/null || true
echo "      Done (modules unloaded or not loaded)"

# ── Step 2: Purge ALL existing NVIDIA / CUDA packages ─────────────────────────
echo "[2/7] Purging existing NVIDIA and CUDA packages..."
apt-get remove --purge -y \
  $(dpkg -l | grep -E '^ii\s+(nvidia|libnvidia|cuda|libcuda|libcudnn|tensorrt)' \
    | awk '{print $2}') 2>/dev/null || true

apt-get autoremove -y
apt-get autoclean -y

# Remove any leftover NVIDIA repo files that might conflict
rm -f /etc/apt/sources.list.d/cuda*.list
rm -f /etc/apt/sources.list.d/nvidia*.list
rm -f /usr/share/keyrings/cuda-*.gpg
rm -f /usr/share/keyrings/nvidia-*.gpg
echo "      Done"

# ── Step 3: Add NVIDIA's official CUDA repository ─────────────────────────────
echo "[3/7] Adding NVIDIA CUDA repository (Ubuntu 24.04)..."
apt-get update -y
apt-get install -y wget

TMP_DEB=$(mktemp --suffix=.deb)
wget -q -O "$TMP_DEB" "$CUDA_KEYRING_URL"
dpkg -i "$TMP_DEB"
rm -f "$TMP_DEB"

apt-get update -y
echo "      Repository added"

# ── Step 4: Detect latest available driver version ────────────────────────────
echo "[4/7] Detecting latest available NVIDIA driver..."

# Find the highest nvidia-driver-NNN package available
LATEST_DRIVER=$(apt-cache search '^nvidia-driver-[0-9]+$' \
  | awk '{print $1}' \
  | grep -E '^nvidia-driver-[0-9]+$' \
  | sort -t- -k3 -n \
  | tail -1)

if [[ -z "$LATEST_DRIVER" ]]; then
  echo "[error] Could not find any nvidia-driver-* package. Check your internet connection."
  exit 1
fi

DRIVER_VERSION="${LATEST_DRIVER#nvidia-driver-}"
echo "      Latest available: $LATEST_DRIVER (version $DRIVER_VERSION)"

# RTX 5080 (Blackwell GB102) requires driver >= 570
MIN_VERSION=570
if [[ "$DRIVER_VERSION" -lt "$MIN_VERSION" ]]; then
  echo "[error] Detected driver $DRIVER_VERSION is below the minimum $MIN_VERSION required for RTX 5080."
  echo "        Make sure the CUDA repo was added correctly and retry."
  exit 1
fi

# ── Step 5: Install driver + open kernel modules (recommended for Blackwell) ──
echo "[5/7] Installing $LATEST_DRIVER..."

# For RTX 50-series (Blackwell), NVIDIA recommends the open kernel module variant.
# Package naming: nvidia-driver-NNN-open (preferred) or nvidia-driver-NNN (bundled open).
# Try the -open variant first; fall back to base package if not available.
OPEN_PKG="nvidia-driver-${DRIVER_VERSION}-open"
BASE_PKG="nvidia-driver-${DRIVER_VERSION}"

if apt-cache show "$OPEN_PKG" &>/dev/null; then
  echo "      Using open kernel module variant: $OPEN_PKG"
  INSTALL_PKG="$OPEN_PKG"
else
  echo "      Open variant not found, using: $BASE_PKG"
  INSTALL_PKG="$BASE_PKG"
fi

apt-get install -y "$INSTALL_PKG" nvidia-settings nvidia-prime

echo "      Installation complete"

# ── Step 6: Rebuild initramfs so the correct module loads at boot ──────────────
echo "[6/7] Rebuilding initramfs..."
update-initramfs -u -k all
echo "      Done"

# ── Step 7: Blacklist the old proprietary module (in case it was installed) ────
echo "[7/7] Ensuring nvidia-open module is preferred..."
cat > /etc/modprobe.d/nvidia-open.conf <<'EOF'
# Use open-source NVIDIA kernel module (required for Blackwell / RTX 5080)
options nvidia NVreg_OpenRmEnableUnsupportedGpus=1
EOF

# If grub is present, update it too
if command -v update-grub &>/dev/null; then
  update-grub 2>/dev/null || true
fi

echo ""
echo "══════════════════════════════════════════════════"
echo "  Installation complete!"
echo ""
echo "  Driver version : $DRIVER_VERSION"
echo "  Kernel modules : nvidia-open (Blackwell-compatible)"
echo ""
echo "  NEXT STEP: Reboot your system, then verify with:"
echo "    sudo reboot"
echo "    # after reboot:"
echo "    nvidia-smi"
echo "══════════════════════════════════════════════════"

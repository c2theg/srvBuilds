#!/usr/bin/env bash
set -euo pipefail

DEVICE_NAME="Pi Audio"

echo "Updating system..."
sudo apt update
sudo apt -y full-upgrade

echo "Installing base audio/Bluetooth tools..."
sudo apt -y install \
  curl git alsa-utils avahi-daemon \
  shairport-sync \
  bluez bluez-tools bluez-alsa-utils

echo "Force Raspberry Pi headphone jack as default audio output..."
sudo raspi-config nonint do_audio 1 || true

cat <<EOF | sudo tee /etc/asound.conf
pcm.!default {
  type hw
  card 0
}

ctl.!default {
  type hw
  card 0
}
EOF

echo "Installing Raspotify..."
curl -sL https://dtcooper.github.io/raspotify/install.sh | sh

echo "Configuring Raspotify..."
sudo mkdir -p /etc/raspotify/conf.d
cat <<EOF | sudo tee /etc/raspotify/conf.d/10-pi-audio.conf
LIBRESPOT_NAME="$DEVICE_NAME"
LIBRESPOT_BACKEND="alsa"
LIBRESPOT_DEVICE="default"
LIBRESPOT_BITRATE="320"
LIBRESPOT_VOLUME_CTRL="alsa"
EOF

echo "Configuring Shairport Sync / AirPlay..."
sudo sed -i 's|^[[:space:]]*name = .*|    name = "'"$DEVICE_NAME AirPlay"'";|' /etc/shairport-sync.conf || true

echo "Enabling services..."
sudo systemctl enable --now avahi-daemon
sudo systemctl enable --now bluetooth
sudo systemctl enable --now raspotify
sudo systemctl enable --now shairport-sync

echo "Setting volume to 80%..."
amixer set Headphone 80% || true
amixer set PCM 80% || true

echo
echo "Done."
echo "Reboot now with: sudo reboot"
echo
echo "After reboot:"
echo "- Spotify app should show: $DEVICE_NAME"
echo "- iPhone/Mac AirPlay should show: $DEVICE_NAME AirPlay"

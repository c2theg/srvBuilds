echo "deb http://linux-packages.resilio.com/resilio-sync/deb resilio-sync non-free" | sudo tee /etc/apt/sources.list.d/resilio-sync.list
curl -LO https://linux-packages.resilio.com/resilio-sync/key.asc
sudo apt-key add key.asc
sudo apt update
sudo apt install resilio-sync

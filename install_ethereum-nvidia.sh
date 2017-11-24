sudo apt-get install software-properties-common
sudo add-apt-repository ppa:ethereum/ethereum
sudo sed 's/jessie/vivid/' -i /etc/apt/sources.list.d/ethereum-ethereum-*.list
sudo apt-get update
sudo apt-get install ethereum ethminer
geth account new
# copy long character sequence within {}, that is your <YOUR_WALLET_ADDRESS>
# if you lose the passphrase, you lose your coins!
sudo apt-get install linux-headers-amd64 build-essential
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/384.90/NVIDIA-Linux-x86_64-384.90.run
chmod +x NVIDIA-Linux-x86_64-384.90.run
sudo ./NVIDIA-Linux-x86_64-384.90.run
ethminer -G -F http://yolo.ethclassic.faith:9999/0x2acd4a4d3c71b9c81f5e48a76766c1860c650f6b --farm-recheck 200
echo done

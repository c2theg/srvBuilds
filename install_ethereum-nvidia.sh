#------------------------------------------
#  http://ethpool.org/
#
#
# setx GPU_FORCE_64BIT_PTR 0
# setx GPU_MAX_HEAP_SIZE 100
# setx GPU_USE_SYNC_OBJECTS 1
# setx GPU_MAX_ALLOC_PERCENT 100
# setx GPU_SINGLE_ALLOC_PERCENT 100
# ethminer.exe --farm-recheck 200 -G -S eu1.ethpool.org:3333 -FS us1.ethpool.org:3333 -O <Your_Ethereum_Address>.<RigName>
#------------------------------------------
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
ethminer -G -F http://us1.ethermine.org:14444/0x2acd4A4D3c71B9c81f5E48a76766c1860c650F6B --farm-recheck 200
echo done






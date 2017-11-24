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
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:ethereum/ethereum
sudo sed 's/jessie/vivid/' -i /etc/apt/sources.list.d/ethereum-ethereum-*.list
sudo apt-get update
sudo apt-get install -y ethereum ethminer
geth account new

sudo apt-get install -y linux-headers-amd64 build-essential
ethminer -G -F http://us1.ethermine.org:14444/0x2acd4A4D3c71B9c81f5E48a76766c1860c650F6B --farm-recheck 200
echo done

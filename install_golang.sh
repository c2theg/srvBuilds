#!/bin/sh
clear
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


Version:  1.2.5
Last Updated:  7/21/2021

"

#--------------------------------------------------------------------------------------------
sudo add-apt-repository -y ppa:longsleep/golang-backports
wait

sudo -E apt-get update
wait

sudo -E apt-get install -y golang-go golang-go.tools
wait

echo ‘PATH=”/usr/lib/go-1.10/bin:$PATH”‘ >> ~/.profile
source ~/.profile
wait

echo -e "\r\n \r\n "
go version

echo -e "\r\n \r\n "
go env
#-----------------------------------
cd ~
if [ ! -d "go" ]
    mkdir go
fi
cd go/
#-----------------------------------
# --- Make Sample File ---
echo "package main" >> helloworld.go
echo "import \"fmt\"" >> helloworld.go
echo "func main() {" >> helloworld.go
echo "        fmt.Printf(\"hello, world\n\")" >> helloworld.go
echo "}" >> helloworld.go
#---------------------------------
chmod u+x helloworld.go
go run helloworld.go
#---------------------------------
echo " \r\n \r\n Done! \r\n \r\n"

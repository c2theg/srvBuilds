#!/bin/sh
#    If you update this from Windows, using Notepad ++, do the following:
#       sudo apt-get -y install dos2unix
#       dos2unix <FILE>
#       chmod u+x <FILE>
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
|   --|   |  _| |_ -|  _| . | . |   | -_|  _|  | | | |  |  |  |  |  |  _| .'| | |
|_____|_|_|_| |_|___|_| |___|  _|_|_|___|_|    |_|_|_|_____|  |_____|_| |__,|_  |
                            |_|                                             |___|

\r\n \r\n
Version:  1.4.9                             \r\n
Last Updated:  8/27/2018
\r\n \r\n
Updating system first..."
sudo -E apt-get update
#wait
sudo -E apt-get upgrade -y
#wait
echo "Downloading required dependencies...\r\n\r\n"
#--------------------------------------------------------------------------------------------
HOST = hostname -I

#------------- Version Detection -------------
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi
echo " Detected: OS: $OS, Version: $VER \r\n \r\n"
#-----------------------------------------------
# - from:  https://docs.docker.com/engine/installation/linux/ubuntu/#os-requirements

echo "Installing Docker... \r\n \r\n"
sudo -E apt-get -y install apt-transport-https ca-certificates curl software-properties-common
wait

if [ $VER = '14.04' ]; then
    #-------- Ubuntu 14.04 ------------------------
    sudo -E apt-get -y install docker.io
    wait
    apt-cache madison docker-ce
else
    if [ $VER = '16.04' ]; then
        #-------- Ubuntu 16.04 ------------------------
        sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        wait
        sudo -E apt-get update
        sudo -E apt-get install -y docker-ce
     elif [ $VER = '18.04' ]; then
        sudo -E apt-get install -y ifupdown aufs-tools debootstrap docker-doc
        sudo -E apt install -y docker.io
     fi
     #----------------------------------------
     wait
     echo "\r\n\r\n \r\n Adding Cockpit (Only for Ubuntu 16.04+) https://cockpit-project.org/  \r\n \r\n"
     sudo add-apt-repository -y ppa:cockpit-project/cockpit
     wait
     sudo -E apt-get install -y cockpit
     wait
     #--- start Cockpit ---
     sudo systemctl start cockpit 
     sudo systemctl enable cockpit
     echo "\r\n \r\n"
     echo "----------------------------  \r\n \r\n"
     echo "Visit: https://$HOST:9090  to access Cockpit! \r\n \r\n"
fi

sudo systemctl start docker
sudo systemctl enable docker
        
wait
echo "Done!"
echo "\r\n \r\n"

echo "\r\n \r\n \r\n"
echo "Running sample container"
sudo docker run hello-world
wait
echo "\r\n \r\n -------------------------------------------------------------- \r\n \r\n"
if [ ! -f ca-key.pem ]; then    
    echo "Generating PKI key... \r\n \r\n"
    # Source: https://docs.docker.com/engine/security/https/

    openssl genrsa -aes256 -out ca-key.pem 4096
    echo "Generating x509 certificate... \r\n \r\n "
    openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem
    openssl genrsa -out server-key.pem 4096
    openssl genrsa -out key.pem 4096

    openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr
    echo "\r\n \r\n -------------------------------------------------------------- \r\n \r\n"
    echo "Updating docker security to allow for remote connections for: $HOST \r\n"
    echo subjectAltName = DNS:$HOST,IP:10.10.10.20,IP:127.0.0.1 >> extfile.cnf
    echo extendedKeyUsage = serverAuth >> extfile.cnf

    openssl x509 -req -days 3650 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf

    echo "\r\n \r\n ---- client info ---- \r\n \r\n"
    openssl req -subj '/CN=client' -new -key key.pem -out client.csr

    echo extendedKeyUsage = clientAuth >> extfile.cnf

    openssl x509 -req -days 3650 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile.cnf

    rm -v client.csr server.csr
    chmod -v 0400 ca-key.pem key.pem server-key.pem
    chmod -v 0444 ca.pem server-cert.pem cert.pem
fi

echo "\r\n \r\n -------------------------------------------------------------- \r\n \r\n"
echo "Downloading a better way to manage containers... \r\n.."
echo " PORTAINER! - https://github.com/portainer/portainer \r\n "

echo "Running command: sudo docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer"
echo "\r\n \r\n"
sudo docker run -d -p 9000:9000 -v "/var/run/docker.sock:/var/run/docker.sock" portainer/portainer

echo "\r\n Local IP's: "
hostname -I
echo "\r\n \r\n"
echo "Visit http://$HOST:9000 in Chrome or Firefox \r\n \r\n"

docker --version
docker ps

echo "Allowing remote access to Docker API... \r\n"
# Source: https://success.docker.com/article/how-do-i-enable-the-remote-api-for-dockerd

mkdir /etc/systemd/system/docker.service.d/
touch /etc/systemd/system/docker.service.d/startup_options.conf
echo [Service] >> /etc/systemd/system/docker.service.d/startup_options.conf
echo ExecStart= >> /etc/systemd/system/docker.service.d/startup_options.conf
echo ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2376 >> /etc/systemd/system/docker.service.d/startup_options.conf

sudo systemctl daemon-reload
sudo systemctl restart docker.service
wait
wait
#----------------------------
echo "\r\n \r\n "
ps aux | grep -i docker
echo "\r\n \r\n "
ss -ntl

#dockerd --tlsverify --tlscacert=ca.pem --tlscert=server-cert.pem --tlskey=server-key.pem -H=0.0.0.0:2376
#docker --tlsverify --tlscacert=ca.pem --tlscert=cert.pem --tlskey=key.pem -H=$HOST:2376 version
  
echo "View Docker commands here: https://docs.docker.com/engine/reference/commandline/container_ls/  \r\n \r\n"
echo " Hello World Container:  sudo docker run -p 3000:80 tutum/hello-world  \r\n \r\n"
echo "\r\n \r\n Docker deployment complete!!! \r\n \r\n"

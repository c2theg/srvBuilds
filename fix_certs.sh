#!/bin/bash
# Updated: 3/4/2026 - Version: 0.0.8
# mainly for Ubuntu 20.04 Server

echo "Updating CA Certificates..."
sudo apt-get update
sudo apt-get install -y --reinstall ca-certificates
sudo apt-get install -y --reinstall openssl libssl1.1 ca-certificates
sudo update-ca-certificates --fresh

sudo ldconfig



echo "Checking Time..."
timedatectl status


sudo timedatectl set-ntp true
sudo timedatectl set-timezone America/New_York



echo "Checking Python..."
python3 -m pip install -U pip
python3 -c "import ssl; print('Python:', ssl.OPENSSL_VERSION); print(ssl.get_default_verify_paths())"
python3 -m pip --version
which python3



echo "Checking OpenSSL..."

which openssl
ls -l "$(which openssl)"
ldd "$(which openssl)" | head


openssl version -a | head -n 3
python3 -c "import ssl; print(ssl.OPENSSL_VERSION); print(ssl.get_default_verify_paths())"
echo | openssl s_client -connect pypi.org:443 -servername pypi.org 2>/dev/null | openssl x509 -noout -issuer -subject
echo | openssl s_client -connect github.com:443 -servername github.com 2>/dev/null | openssl x509 -noout -issuer -subject


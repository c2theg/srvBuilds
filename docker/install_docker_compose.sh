clear
echo "\r\n \r\n"
echo "Installing Docker Compose... (From: https://docs.docker.com/compose/install/ )  \r\n \r\n "
sudo curl -L "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
wait
sudo chmod +x /usr/local/bin/docker-compose
echo "\r\n \r\n"
docker-compose --version

echo "Done! \r\n \r\n"

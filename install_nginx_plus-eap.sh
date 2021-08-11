#!/bin/bash
Version="0.1.20"
Updated="8/10/2021"
# --------------------------------------------
#  SOURCES 
# https://cs.nginx.com/repo_setup
# https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-plus/#install_debian_ubuntu
# https://docs.nginx.com/nginx-app-protect/admin-guide/#ubuntu-18-04-installation


# NGINX Plus can be installed on the following versions of Debian or Ubuntu:
	# Debian 9 (“Stretch”)
	# Debian 10 (“Buster”)
	# Ubuntu 16.04 LTS (“Xenial”) (i386, x86_64, ppc64le, aarch64)
	# Ubuntu 18.04 LTS (“Bionic”)
	# Ubuntu 20.04 (“Focal”)
# --------------------------------------------
clear

echo "

Installation of 

  _   _  _____ _____ _   ___   __
 | \ | |/ ____|_   _| \ | \ \ / /
 |  \| | |  __  | | |  \| |\ V / 
 |     | | |_ | | | | .   | > <  
 | |\  | |__| |_| |_| |\  |/ . \ 
 |_| \_|\_____|_____|_| \_/_/ \_\

    PLUS+  &  App Protect (EAP)


Version: $Version
Last Updated: $Updated

"

if [ -d "/etc/nginx/" ]; then
	#If you already have old NGINX packages in your system, back up your configs and logs:
	echo "Backing up old configs (to: /etc/nginx-plus-backup)...  "
	mkdir -p /etc/nginx-plus-backup
	mkdir -p /var/log/nginx-plus-backup

	sudo cp -a /etc/nginx /etc/nginx-plus-backup
	sudo cp -a /var/log/nginx /var/log/nginx-plus-backup
	echo "DONE!  "
fi

if [ -s "nginx-repo.key" ]; then
	sudo mkdir -p /etc/ssl/nginx
	sudo mkdir -p /etc/nginx/sites-enabled/
	sudo mkdir -p /etc/nginx/sites-available/
	sudo mkdir -p /etc/nginx/certs/
	sudo mkdir -p /etc/nginx/snippets/
	
	
	wget -O /etc/nginx/certs/lets-encrypt-x3-cross-signed.pem "https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem" 
	cp nginx-repo.key /etc/ssl/nginx/
	cp nginx-repo.crt /etc/ssl/nginx/
	chmod 644 /etc/ssl/nginx/*

	if [ -f /etc/lsb-release ]; then
		#--- UBUNTU  ---- by: christopher gray

		#Download and add the NGINX signing key:
		curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo apt-key add -
		sudo wget https://cs.nginx.com/static/keys/nginx_signing.key && sudo apt-key add nginx_signing.keys

		#Install apt utils:
		sudo apt-get install -y apt-transport-https lsb-release ca-certificates
		#Add NGINX Plus repository:

		# Debian
		#printf "deb https://plus-pkgs.nginx.com/debian `lsb_release -cs` nginx-plus\n" | sudo tee /etc/apt/sources.list.d/nginx-plus.list
		# Ubuntu
		printf "deb https://plus-pkgs.nginx.com/ubuntu `lsb_release -cs` nginx-plus\n" | sudo tee /etc/apt/sources.list.d/nginx-plus.list


		echo "Verify that you now have the proper key: "
		sudo apt-key fingerprint ABF5BD827BD9BF62
			
		#Download the apt configuration to /etc/apt/apt.conf.d:
		#sudo wget -P /etc/apt/apt.conf.d https://cs.nginx.com/static/files/90nginx
		#sudo wget -q -O /etc/apt/apt.conf.d/90nginx https://cs.nginx.com/static/files/90nginx
		sudo wget -P /etc/apt/apt.conf.d https://cs.nginx.com/static/files/90nginx

		#Update the repository and install NGINX Plus:
		sudo -E apt-get -o Acquire::ForceIPv4=true update
		#sudo apt-get update 
		#sudo apt-get update --allow-unauthenticated
		sudo apt-get update --allow-insecure-repositories

		# deb https://plus-pkgs.nginx.com/ubuntu focal nginx-plus
		# deb [trusted=yes] https://plus-pkgs.nginx.com/ubuntu focal nginx-plus

		sudo apt-get install -y nginx-plus
		wait


		#**********************************************
		#---      NGINX APP PROTECT - Install       ---
		#**********************************************
		sudo apt-get install -y app-protect

		# Load the NGINX App Protect module on the main context in the nginx.conf file: (Add to nginx.conf)
		#      load_module modules/ngx_http_app_protect_module.so;

		#  Enable NGINX App Protect on an http/server/location context in the nginx.conf via:  (Add to each vHost)
		#      app_protect_enable on;

		sudo service nginx restart


		#**********************************************
		#--- Updating App Protect Attack Signatures ---
		#**********************************************
		printf "deb https://app-protect-security-updates.nginx.com/ubuntu/ `lsb_release -cs` nginx-plus\n" | sudo tee /etc/apt/sources.list.d/app-protect-security-updates.list
		sudo wget https://cs.nginx.com/static/keys/app-protect-security-updates.key && sudo apt-key add app-protect-security-updates.key
		sudo wget -P /etc/apt/apt.conf.d https://cs.nginx.com/static/files/90app-protect-security-updates
		sudo apt-get update && sudo apt-get install -y app-protect-attack-signatures


		#**********************************************
		#--- Updating App Protect Threat Campaigns ---
		#**********************************************
		sudo apt-get install -y app-protect-threat-campaigns
		

		# -- Show Installs --
		echo "\r\n \r\n \r\n"
		sudo apt-cache policy app-protect-attack-signatures
		sudo apt-cache policy app-protect-threat-campaigns


		# Check the latest version at: https://docs.nginx.com/nginx/releases/
		sudo service nginx restart
		nginx -V
	else

		#------- REDHAT ----------
		#Installation instructions for RHEL 7.4+ / CentOS 7.4+ / Oracle Linux 7.4+
		sudo yum install ca-certificates
		sudo wget -P /etc/yum.repos.d https://cs.nginx.com/static/files/nginx-plus-7.4.repo
		#sudo wget -P /etc/yum.repos.d https://cs.nginx.com/static/files/nginx-plus-7.repo
		sudo yum install -y nginx-plus
		wait
		nginx -v
		sudo systemctl enable nginx.service 
		sudo systemctl start nginx.service
	fi

	echo "

	DONE! You can now modify the config at /etc/nginx/nginx.conf

	"

else

	echo "Log in to NGINX Customer Portal and download the following two files and put them in this directory. 

	nginx-repo.key
	nginx-repo.crt

	Use your SCP client or other secure file transfer tools to place it on the server. Then re-run this script

	"
fi

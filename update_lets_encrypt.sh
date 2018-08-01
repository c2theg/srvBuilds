# look at: https://www.onepagezen.com/letsencrypt-auto-renew-certbot-apache/#step1

sudo ~/.local/share/letsencrypt/bin/letsencrypt certonly \
--agree-tos --email someone@gmail.com \
--webroot \
--webroot-path  /var/www \
--domains <YOUR WEBSITE>


if [ $? -ne 0 ]
 then
        ERRORLOG=`tail /var/log/letsencrypt/letsencrypt.log`
        echo -e "The Lets Encrypt Cert has not been renewed! \n \n" $ERRORLOG | mail -s "Lets Encrypt Cert Alert" someone@gmail.com
 else
        service nginx restart
fi

exit 0

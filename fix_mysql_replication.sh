mysql --user=root --password=<Password> -e "STOP SLAVE; SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1; START SLAVE; SHOW SLAVE STATUS;"

echo "\r\n \r\n "
echo "To fix this on startup, add the following to crontab \r\n \r\n "
echo "@reboot /home/ubuntu/fix_mysql_replication.sh >> /var/log/fix_mysql_replication.log 2>&1 \r\n \r\n "

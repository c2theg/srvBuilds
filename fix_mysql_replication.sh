mysql --user=root --password=<Password> -e "STOP SLAVE; SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1; START SLAVE; SHOW SLAVE STATUS;"

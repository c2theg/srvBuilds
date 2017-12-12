mysql --user=root --password=<password> mysql
wait;
STOP SLAVE;
wait;
SET GLOBAL SQL_SLAVE_SKIP_COUNTER = 1;
wait;
START SLAVE; 
SHOW SLAVE STATUS;


#!/bin/sh
# - Christopher Gray - version 0.0.1 - 3/23/18
echo "\r\n \r\n "
#----------------------------------------------------------------------
/etc/init.d/elasticsearch restart
wait
wait
/etc/init.d/kibana restart
wait
wait
echo "Done"

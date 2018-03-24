#!/bin/sh
# - Christopher Gray - version 0.7.5 - 3/23/18
echo "\r\n \r\n "
#----------------------------------------------------------------------
echo "\r\n \r\n  Processes \r\n \r\n"
curl 127.0.0.1:9200/_nodes/process?pretty

echo "\r\n \r\n  Nodes Stats \r\n \r\n"
curl -XGET 'localhost:9200/_cat/nodes?v&pretty'

echo "\r\n \r\n  Cluster Templates' \r\n \r\n"
curl -XGET 'localhost:9200/_template/*?pretty'

echo "\r\n \r\n  Cluster cat Health \r\n \r\n"
curl -XGET 'localhost:9200/_cat/health?v&pretty'

echo "\r\n \r\n  Cluster Indices \r\n \r\n"
curl -XGET 'localhost:9200/_cat/indices?v&pretty'

echo "\r\n \r\n  Cluster Health \r\n \r\n"
curl -XGET http://localhost:9200/_cluster/health?pretty

echo "\r\n \r\n  Cluster Health - Shards \r\n \r\n"
curl -XGET http://localhost:9200/_cat/shards

echo "\r\n \r\n  Cluster Allocation Details \r\n \r\n"
curl -H 'Content-Type: application/json' -X GET 'localhost:9200/_cluster/allocation/explain?pretty'

echo "\r\n \r\n  Cluster Allocation brief \r\n \r\n"
curl -s 'localhost:9200/_cat/allocation?v'

#----------------------------------------------------------------------

#netstat -a -n | grep tcp | grep 9200
#ps -ef | grep elasticsearch

netstat -tulnp

echo "\r\n \r\n DONE \r\n \r\n \r\n"

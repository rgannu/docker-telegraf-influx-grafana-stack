#!/bin/bash

# cross-platform version of gnu 'readlink -f'
realpath=$(python -c 'import os; import sys; print (os.path.realpath(sys.argv[1]))' "$0")
bin=`dirname "$realpath"`
bin=`cd "$bin">/dev/null; pwd`

MAX=500
MIN=100

# docker exec -i kafkacat kafkacat -h
# -K, (comma is the delimiter)
# -P produce
# -t topic
while [[ 1 ]];do
  random_val=`echo $(($MIN + RANDOM % $MAX))`
  docker exec -i kafkacat kafkacat -b kafka:9092 -T -P -t json_01 <<EOF
{ "schema": { "type": "struct", "fields": [ { "field": "tags" , "type": "map", "keys": { "type": "string", "optional": false }, "values": { "type": "string", "optional": false }, "optional": false}, { "field": "stock", "type": "double", "optional": true } ], "optional": false, "version": 1 }, "payload": { "tags": { "host": "FOO", "product": "wibble" }, "stock": $random_val } }
EOF
  echo "sleep for 5 secs"
  sleep 5
done

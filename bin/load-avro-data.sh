#!/bin/bash

# cross-platform version of gnu 'readlink -f'
realpath=$(python -c 'import os; import sys; print (os.path.realpath(sys.argv[1]))' "$0")
bin=`dirname "$realpath"`
bin=`cd "$bin">/dev/null; pwd`

MAX=500
MIN=100

while [[ 1 ]];do
  random_val=`echo $(($MIN + RANDOM % $MAX))`
  docker exec -i schema-registry /usr/bin/kafka-avro-console-producer --broker-list kafka:9092 --topic avro_01 --property schema.registry.url='http://schema-registry:18081' --property value.schema='{ "type": "record", "name": "myrecord", "fields": [ { "name": "tags", "type": { "type": "map", "values": "string" } }, { "name": "stock", "type": "double" } ] }' <<EOF
{ "tags": { "host": "FOO", "product": "p2" }, "stock": $random_val }
EOF
  echo "sleep for 5 secs"
  sleep 5
done


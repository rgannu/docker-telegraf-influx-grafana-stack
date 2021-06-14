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
  random_total_val=`echo $(($MIN + RANDOM % $MAX))`
  random_update_val=`echo $(($MIN + RANDOM % $MAX))`
  random_create_val=`echo $(($MIN + RANDOM % $MAX))`
  random_delete_val=`echo $(($MIN + RANDOM % $MAX))`

  docker exec -i kafkacat kafkacat -b kafka:9092 -T -P -t statistics-topic <<EOF
{ "start.event_ts.ns":1622474640000000000, "operations":{ "creates":$random_create_val, "deletes":$random_delete_val, "reads":0, "total":$random_total_val, "updates":$random_update_val }, "end.event_ts.ns":1622474460000000000, "topic_operations":{ "dbanalytics.skybridge.geo_zone":{ "creates":124672, "deletes":125154, "reads":0, "total":$random_total_val, "updates":$random_update_val }, "dbanalytics.skybridge.schema_version":{ "creates":0, "deletes":0, "reads":0, "total":$random_total_val, "updates":$random_update_val } } }
EOF

  echo "sleep for 5 secs"
  sleep 5
done

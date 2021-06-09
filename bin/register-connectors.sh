#!/bin/bash

# cross-platform version of gnu 'readlink -f'
realpath=$(python -c 'import os; import sys; print (os.path.realpath(sys.argv[1]))' "$0")
bin=`dirname "$realpath"`
bin=`cd "$bin">/dev/null; pwd`

# set an initial value for the flag
SOURCE_N_SINK=1
SOURCE=0
SINK=0
SLEEP_SECS=0

# read the options
OPTS=$(getopt -s bash --option ios: --longoptions source,sink,sleep: -n `basename "$0"` -- "$@")
eval set -- "$OPTS"

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -i|--source) SOURCE=1 ; SOURCE_N_SINK=0 ; shift ;;
    -o|--sink) SINK=1 ; SOURCE_N_SINK=0 ; shift ;;
    -s|--sleep) SLEEP_SECS=$2 ; shift 2 ;;
    --) shift ; break ;;
    *) echo "Internal error!" ; exit 1 ;;
  esac
done

if [[ ${SOURCE} -eq 1 ]] || [[ ${SOURCE_N_SINK} -eq 1 ]]
then
  echo "Registering SOURCE connectors..."
  echo "-None-"
fi

if [[ $? != 0 ]]; then
  exit 1;
fi

if [[ ${SINK} -eq 1 ]] || [[ ${SOURCE_N_SINK} -eq 1 ]]
then
  echo "Registering SINK connectors..."
  curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:18083/connectors/ -d @"${bin}/"register-influx-json-sink-connector.json
  curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:18083/connectors/ -d @"${bin}/"register-influx-avro-sink-connector.json
fi

if [[ $? != 0 ]]; then
  exit 1;
fi

if [[ $SLEEP_SECS -gt 0 ]]; then
  echo "Sleeping for $SLEEP_SECS..."
  sleep $SLEEP_SECS
fi

exit 0

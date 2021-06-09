#!/bin/bash

REGISTERED_CONNECTORS=`curl -s http://localhost:18083/connectors/ | sed -e 's/\[//g' -e 's/\]//g' -e 's/\"//g' -e 's/\,/\n/g'`
if [[ $? != 0 || "${REGISTERED_CONNECTORS}" == "" ]];then
  echo "WARN: No connectors are registered"
fi

for connector in ${REGISTERED_CONNECTORS}; do
  status_json=`curl -s http://localhost:18083/connectors/${connector}/status`
  connector_state=`echo ${status_json} | jq .connector.state | sed -e 's/\"//g'`
  task_state=`echo ${status_json} | jq .tasks[0].state | sed -e 's/\"//g'`
  echo "Status of the connector: \"${connector}\" is in state \"${connector_state}\""
  if [[ ${connector_state} != "RUNNING" ]];then
    echo "WARN: Connector: \"${connector}\" is in state \"${connector_state}\""
    exit 1
  fi
  echo " - Task status: \"${task_state}\""
  if [[ ${task_state} != "RUNNING" ]];then
    echo "WARN: Task state of the connector: \"${connector}\" is in state \"${task_state}\""
    task_trace=`echo ${status_json} | jq .tasks[0].trace | sed -e 's/\"//g'`
    echo "WARN: Task trace: \"${task_trace}\""
    exit 1
  fi
done

exit 0

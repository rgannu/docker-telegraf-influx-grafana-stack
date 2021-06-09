#!/bin/bash
set -e

mkdir -p /secrets
ENV_FILE="/secrets/env"
AMQP_PROP_FILE="/secrets/amqp.properties"
CONNECT_SOURCE_PROP_FILE="/secrets/connect-source.properties"

# Create the secrets file
echo "# Environment variables (auto-generated)" > ${ENV_FILE}
echo "# Secrets file (auto-generated)" > ${AMQP_PROP_FILE}
echo "# Secrets file (auto-generated)" > ${CONNECT_SOURCE_PROP_FILE}

#
# Process all environment variables that start with 'AMQP_' and 'CONNECT_SOURCE_'
#
for VAR in `env`
do
  echo ${VAR} >> ${ENV_FILE}
  PREFIX=""
  PROP_FILE=""
  if [[ ${VAR} =~ ^AMQP ]]; then
    PREFIX="AMQP"
    PROP_FILE="${AMQP_PROP_FILE}"
  elif [[ ${VAR} =~ ^CONNECT_SOURCE ]]; then
    PREFIX="CONNECT_SOURCE"
    PROP_FILE="${CONNECT_SOURCE_PROP_FILE}"
  fi

  if [[ "${PREFIX}" != "" ]]; then
    prop_name=`echo "$VAR" | sed -e "s/^${PREFIX}_//g" | awk -F'=' '{print $1}' | tr '[:upper:]' '[:lower:]' | tr _ .`
    prop_val=`echo "$VAR" | awk -F'=' '{$1="";print substr($0,2)}' | sed -e "s/ /=/g"`
    echo "--- Setting property : $prop_name=${prop_val}"
    echo "$prop_name=${prop_val}" >> ${PROP_FILE}
  fi
done

#!/bin/bash

# Remove all connectors
for connector in `curl -s http://localhost:18083/connectors | jq -r .[]`; do
  echo "Removing connector: ${connector}"
  curl -X DELETE http://localhost:18083/connectors/${connector}
done

if [[ $? != 0 ]]; then
  exit 1;
fi

exit 0

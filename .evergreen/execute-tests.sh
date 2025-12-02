#!/bin/bash

set -eu

SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $SCRIPT_DIR)

# Source the configuration.
cd ${ROOT_DIR}/${DIR}
set -a
source config.env
set +a

cd ${REPO_NAME}

MAX_ATTEMPTS=3
ATTEMPT=1
EXIT_CODE=0

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do  
  bash ${ROOT_DIR}/${DIR}/run.sh
    
  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then  
    break  
  else  
    echo "Tests failed with exit code $EXIT_CODE on attempt $ATTEMPT of $MAX_ATTEMPTS..."  
    ((ATTEMPT++))  
  fi  
done  

if [ $EXIT_CODE -ne 0 ]; then  
  echo "Tests failed after $MAX_ATTEMPTS attempts."
fi  
exit $EXIT_CODE

#!/bin/bash

set -eu

SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $SCRIPT_DIR)

# Source the secrets.
source $ROOT_DIR/secrets-export.sh

# Source the configuration.
cd ${ROOT_DIR}/${DIR}
set -a
source config.env
set +a

cd ${REPO_NAME}

bash ${ROOT_DIR}/${DIR}/run.sh

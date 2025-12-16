#!/bin/bash

# WORKING_DIR = src/langchain-python/langchain
set -eu

# Get the MONGODB_URI and OPENAI_API_KEY.
SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $SCRIPT_DIR)
. $ROOT_DIR/env.sh

. $ROOT_DIR/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

# shellcheck disable=SC2164
cd libs/langchain-mongodb

$PYTHON_BINARY -m venv venv_pipeline
source venv_pipeline/bin/activate

SSL_CERT_FILE=$($PYTHON_BINARY -c "import certifi; print(certifi.where())")
export SSL_CERT_FILE

pip install uv rust-just

just install

just unit_tests

just integration_tests

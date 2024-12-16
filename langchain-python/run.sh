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

pip install poetry

poetry lock --no-update

poetry install --with dev

export MONGODB_URI=$MONGODB_URI
export OPENAI_API_KEY=$OPENAI_API_KEY

make test

make integration_test

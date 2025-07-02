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

pip install uv rust-just

just install

# Use the o4-mini model from Azure for tests.
export AZURE_OPENAI_ENDPOINT=$AZURE_OPENAI_O4_MINI_URI
export AZURE_OPENAI_API_KEY=$AZURE_OPENAI_O4_MINI_KEY

just tests

just integration_tests

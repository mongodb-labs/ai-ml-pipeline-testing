#!/bin/bash

# WORKING_DIR = src/langchain-python/langchain
set -eu

# Get the MONGODB_URI and OPENAI_API_KEY.
# shellcheck disable=SC2154
. $workdir/src/env.sh

# shellcheck disable=SC2154
. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

# shellcheck disable=SC2164
cd libs/mongodb

 $PYTHON_BINARY -m venv venv_pipeline
 source venv_pipeline/bin/activate

pip install poetry

poetry lock --no-update

poetry install --with test --with test_integration

export MONGODB_ATLAS_URI=$MONGODB_URI
export OPENAI_API_KEY=$OPENAI_API_KEY

make test

make integration_test

#!/bin/bash

# WORKING_DIR = src/langchain-python/langchain
set -x

# shellcheck disable=SC2154
. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

# shellcheck disable=SC2164
cd libs/mongodb

 $PYTHON_BINARY -m venv venv_pipeline
 source venv_pipeline/bin/activate

pip install poetry

poetry lock --no-update

poetry install --with dev

MONGODB_ATLAS_URI=$(fetch_local_atlas_uri)

export MONGODB_ATLAS_URI
# shellcheck disable=SC2154
export OPENAI_API_KEY=$openai_api_key

make test

make integration_test

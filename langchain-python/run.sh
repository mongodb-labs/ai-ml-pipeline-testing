#!/bin/bash

# WORKING_DIR = src/langchain-python/langchain
set -x

. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

cd libs/partners/mongodb

 $PYTHON_BINARY -m venv venv_pipeline
 source venv_pipeline/bin/activate

pip install poetry

poetry lock --no-update

poetry install --with test --with test_integration

export MONGODB_ATLAS_URI=$(fetch_local_atlas_uri)
export OPENAI_API_KEY=$openai_api_key

make test

make integration_test

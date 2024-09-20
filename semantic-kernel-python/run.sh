#!/bin/bash

set -x

. $workdir/src/.evergreen/utils.sh

CONN_STRING=$($atlas deployments connect $DIR --connectWith connectionString)
PYTHON_BINARY=$(find_python3)


# WORKING_DIR = src/semantic-kernel-python/semantic-kernel
cd python


# Install Poetry into base python
$PYTHON_BINARY -m pip install -U pip poetry
# Create a package specific poetry environment
$PYTHON_BINARY -m poetry env use $PYTHON_BINARY
# Activate the poetry env, which itself does not include poetry
source $($PYTHON_BINARY -m poetry env info --path)/bin/activate
# Recreate the poetry lock file
$PYTHON_BINARY -m poetry lock --no-update
# Install from pyproject.toml into package specific environment
$PYTHON_BINARY -m poetry install ".[mongodb]" --with dev

# Create .env file
python -c "from dotenv import set_key; set_key('.env', 'OPENAI_API_KEY', '$openai_api_key')"
python -c "from dotenv import set_key; set_key('.env', 'MONGODB_ATLAS_CONNECTION_STRING', '$CONN_STRING')"

# Workaround to test vector search first
OPENAI_API_KEY=$openai_api_key \
OPENAI_ORG_ID="" \
AZURE_OPENAI_DEPLOYMENT_NAME="" \
AZURE_OPENAI_ENDPOINT="" \
AZURE_OPENAI_API_KEY="" \
MONGODB_ATLAS_CONNECTION_STRING=$CONN_STRING \
Python_Integration_Tests=1 \
$PYTHON_BINARY -m poetry run pytest tests/integration/connectors/memory/test_mongodb_atlas.py -k test_collection_knn

# Stored in evergreen VARIABLES
OPENAI_API_KEY=$openai_api_key \
OPENAI_ORG_ID="" \
AZURE_OPENAI_DEPLOYMENT_NAME="" \
AZURE_OPENAI_ENDPOINT="" \
AZURE_OPENAI_API_KEY="" \
MONGODB_ATLAS_CONNECTION_STRING=$CONN_STRING \
Python_Integration_Tests=1 \
$PYTHON_BINARY -m poetry run pytest tests/integration/connectors/memory/test_mongodb_atlas.py

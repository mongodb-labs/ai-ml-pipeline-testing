#!/bin/bash

set -x

CONN_STRING=$($atlas deployments connect $DIR --connectWith connectionString)

# WORKING_DIR = src/semantic-kernel-python/semantic-kernel
cd python

PYTHON_BINARY=/opt/python/3.10/bin/python3
$PYTHON_BINARY -m venv .
source ./bin/activate

pip install poetry
pip install pytest
pip install grpcio
poetry install

# Workaround to test vector search first
OPENAI_API_KEY=$openai_api_key \
OPENAI_ORG_ID="" \
AZURE_OPENAI_DEPLOYMENT_NAME="" \
AZURE_OPENAI_ENDPOINT="" \
AZURE_OPENAI_API_KEY="" \
MONGODB_ATLAS_CONNECTION_STRING=$($atlas deployments connect $DIR --connectWith connectionString) \
Python_Integration_Tests=1 \
poetry run pytest tests/integration/connectors/memory/test_mongodb_atlas.py -k test_collection_knn

# Stored in evergreen VARIABLES
OPENAI_API_KEY=$openai_api_key \
OPENAI_ORG_ID="" \
AZURE_OPENAI_DEPLOYMENT_NAME="" \
AZURE_OPENAI_ENDPOINT="" \
AZURE_OPENAI_API_KEY="" \
MONGODB_ATLAS_CONNECTION_STRING=$($atlas deployments connect $DIR --connectWith connectionString) \
Python_Integration_Tests=1 \
poetry run pytest tests/integration/connectors/memory/test_mongodb_atlas.py

#!/bin/bash

set -x

. $workdir/src/.evergreen/utils.sh

CONN_STRING=$(fetch_local_atlas_uri)
PYTHON_BINARY=$(find_python3)

# WORKING_DIR = src/semantic-kernel-python/semantic-kernel
cd python

make install

OPENAI_API_KEY=$openai_api_key \
    OPENAI_ORG_ID="" \
    AZURE_OPENAI_DEPLOYMENT_NAME="" \
    AZURE_OPENAI_ENDPOINT="" \
    AZURE_OPENAI_API_KEY="" \
    MONGODB_ATLAS_CONNECTION_STRING=$CONN_STRING \
    Python_Integration_Tests=1 \
    uv run pytest tests/integration/connectors/memory/test_mongodb_atlas.py -k test_collection_knn

OPENAI_API_KEY=$openai_api_key \
    OPENAI_ORG_ID="" \
    AZURE_OPENAI_DEPLOYMENT_NAME="" \
    AZURE_OPENAI_ENDPOINT="" \
    AZURE_OPENAI_API_KEY="" \
    MONGODB_ATLAS_CONNECTION_STRING=$CONN_STRING \
    Python_Integration_Tests=1 \
    uv run pytest tests/integration/connectors/memory/test_mongodb_atlas.py

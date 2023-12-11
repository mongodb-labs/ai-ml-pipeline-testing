#!/bin/bash

set -x

# WORKING_DIR = src/semantic-kernel-python/semantic-kernel
cd python

pip install poetry
poetry install

# Stored in evergreen VARIABLES
OPENAI_API_KEY=$openai_api_key \
OPENAI_ORG_ID="" \
AZURE_OPENAI_DEPLOYMENT_NAME="" \
AZURE_OPENAI_ENDPOINT="" \
AZURE_OPENAI_API_KEY="" \
MONGODB_ATLAS_CONNECTION_STRING=$semantic_kernel_mongodb_uri \
Python_Integration_Tests=1 \
poetry run pytest tests/integration/connectors/memory/test_mongodb_atlas.py

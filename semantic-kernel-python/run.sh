#!/bin/bash

set -eu

# Get the MONGODB_URI and OPENAI_API_KEY.
# shellcheck disable=SC2154
. $workdir/src/secrets-export.sh

# shellcheck disable=SC2154
. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

# WORKING_DIR = src/semantic-kernel-python/semantic-kernel
# shellcheck disable=SC2164
cd python

# Temporary solution until https://github.com/microsoft/semantic-kernel/issues/9067 resolves
$PYTHON_BINARY -m venv venv_wrapper
source venv_wrapper/bin/activate
pip install --upgrade uv

make install-python
make install-sk
make install-pre-commit

# shellcheck disable=SC2154
OPENAI_API_KEY="$OPENAI_API_KEY" \
    OPENAI_ORG_ID="" \
    AZURE_OPENAI_DEPLOYMENT_NAME="" \
    AZURE_OPENAI_ENDPOINT="" \
    AZURE_OPENAI_API_KEY="" \
    MONGODB_ATLAS_CONNECTION_STRING=$MONGODB_URI \
    Python_Integration_Tests=1 \
    uv run pytest tests/integration/memory/memory_stores/test_mongodb_atlas_memory_store.py -k test_collection_knn

# shellcheck disable=SC2154
OPENAI_API_KEY="$OPENAI_API_KEY" \
    OPENAI_ORG_ID="" \
    AZURE_OPENAI_DEPLOYMENT_NAME="" \
    AZURE_OPENAI_ENDPOINT="" \
    AZURE_OPENAI_API_KEY="" \
    MONGODB_ATLAS_CONNECTION_STRING=$MONGODB_URI \
    Python_Integration_Tests=1 \
    uv run pytest tests/integration/memory/memory_stores/test_mongodb_atlas_memory_store.py

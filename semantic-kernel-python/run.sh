#!/bin/bash

set -eu

# Get the MONGODB_URI and OPENAI_API_KEY.
SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $SCRIPT_DIR)
. $ROOT_DIR/env.sh

. $ROOT_DIR/.evergreen/utils.sh

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

cp $SCRIPT_DIR/test_mongodb_atlas_memory_store.py .

# shellcheck disable=SC2154
OPENAI_API_KEY="" \
    OPENAI_ORG_ID="" \
    AZURE_OPENAI_DEPLOYMENT_NAME="" \
    AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_O4_MINI_URI" \
    AZURE_OPENAI_API_KEY="$AZURE_OPENAI_O4_MINI_KEY" \
    MONGODB_ATLAS_CONNECTION_STRING=$MONGODB_URI \
    Python_Integration_Tests=1 \
    uv run pytest test_mongodb_atlas_memory_store.py -k test_collection_knn

# shellcheck disable=SC2154
OPENAI_API_KEY="" \
    OPENAI_ORG_ID="" \
    AZURE_OPENAI_DEPLOYMENT_NAME="" \
    AZURE_OPENAI_ENDPOINT="$AZURE_OPENAI_O4_MINI_URI" \
    AZURE_OPENAI_API_KEY="$AZURE_OPENAI_O4_MINI_KEY" \
    MONGODB_ATLAS_CONNECTION_STRING=$MONGODB_URI \
    Python_Integration_Tests=1 \
    uv run pytest test_mongodb_atlas_memory_store.py

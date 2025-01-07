#!/bin/bash

# chat-gpt-retrieval-plugin is a poetry run project

set -eu

# Get the MONGODB_URI and OPENAI_API_KEY.
SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $SCRIPT_DIR)
. $ROOT_DIR/env.sh

. $ROOT_DIR/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# Install Poetry
$PYTHON_BINARY -m venv .venv
. .venv/bin/activate
PYTHON_BINARY=$(which python)
$PYTHON_BINARY -m pip install -U pip poetry
# Create a package specific poetry environment
$PYTHON_BINARY -m poetry env use $PYTHON_BINARY
# Activate the poetry env, which itself does not include poetry
. "$($PYTHON_BINARY -m poetry env info --path)/bin/activate"
# Recreate the poetry lock file
$PYTHON_BINARY -m poetry lock
# Install from pyproject.toml into package specific environment
$PYTHON_BINARY -m poetry install --with dev

# Run tests.
MONGODB_URI="$MONGODB_URI" \
OPENAI_API_KEY="$OPENAI_API_KEY" \
DATASTORE="mongodb" \
BEARER_TOKEN="staylowandkeepmoving" \
MONGODB_DATABASE="chatgpt_retrieval_plugin_test_db" \
MONGODB_COLLECTION="chatgpt_retrieval_plugin_test_vectorstore" \
MONGODB_INDEX="vector_index" \
EMBEDDING_MODEL="text-embedding-3-small" \
EMBEDDING_DIMENSION="1536" \
$PYTHON_BINARY -m poetry run pytest -v tests/datastore/providers/mongodb_atlas/

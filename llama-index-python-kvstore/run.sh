#!/bin/bash

set -eu

# Get the MONGODB_URI and OPENAI_API_KEY.
SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $SCRIPT_DIR)
. $ROOT_DIR/env.sh

. $ROOT_DIR/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# cd to the MongoDB integration. It has its own project
# shellcheck disable=SC2164
cd llama-index-integrations/storage/kvstore/llama-index-storage-kvstore-mongodb

# Install Poetry
$PYTHON_BINARY -m venv .venv
. .venv/bin/activate
PYTHON_BINARY=$(which python)
$PYTHON_BINARY -m pip install -U pip poetry
# Create a package specific poetry environment
$PYTHON_BINARY -m poetry env use $PYTHON_BINARY
# Activate the poetry env, which itself does not include poetry
. "$($PYTHON_BINARY -m poetry env info --path)/bin/activate"
# PYTHON-4522: Will fix requirement in llama-index repo
$PYTHON_BINARY -m poetry add motor
# Recreate the poetry lock file
$PYTHON_BINARY -m poetry lock
# Install from pyproject.toml into package specific environment
$PYTHON_BINARY -m poetry install --with dev

# Run tests.
MONGODB_URI="$MONGODB_URI" \
OPENAI_API_KEY="$OPENAI_API_KEY" \
MONGODB_DATABASE="llama_index_test_db" \
MONGODB_COLLECTION="llama_index_test_kvstore" \
$PYTHON_BINARY -m poetry run pytest -v tests

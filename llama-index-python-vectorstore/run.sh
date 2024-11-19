#!/bin/sh

set -x

# Get the MONGODB_URI and OPENAI_API_KEY.
# shellcheck disable=SC2154
source $workdir/src/secrets-export.sh

# shellcheck disable=SC2154
. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# cd to the MongoDB integration. It has its own project
# shellcheck disable=SC2164
cd llama-index-integrations/vector_stores/llama-index-vector-stores-mongodb

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
$PYTHON_BINARY -m poetry lock --no-update
# Install from pyproject.toml into package specific environment
$PYTHON_BINARY -m poetry install --with dev

# Run tests.
MONGODB_DATABASE="llama_index_test_db" \
MONGODB_COLLECTION="llama_index_test_vectorstore" \
MONGODB_INDEX="vector_index" \
$PYTHON_BINARY -m poetry run pytest -v tests

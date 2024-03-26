#!/bin/sh

set -x

. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# cd to the MongoDB integration. It has its own project
cd llama-index-integrations/vector_stores/llama-index-vector-stores-mongodb

# Install Poetry into base python
$PYTHON_BINARY -m pip install -U pip poetry
# Create a package specific poetry environment
$PYTHON_BINARY -m poetry env use $PYTHON_BINARY
# Activate the poetry env, which itself does not include poetry
source $($PYTHON_BINARY -m poetry env info --path)/bin/activate
# Recreate the poetry lock file
$PYTHON_BINARY -m poetry lock --no-update
# Install from pyproject.toml into package specific environment
$PYTHON_BINARY -m poetry install --with dev

# Run tests. Sensitive variables in Evergreen come from Evergreen project: ai-ml-pipeline-testing/
OPENAI_API_KEY=$openai_api_key \
MONGO_URI=$llama_index_mongodb_uri \
MONGODB_DATABASE="llama_index_test_db" \
MONGODB_COLLECTION="llama_index_test_vectorstore" \
MONGODB_INDEX="vector_index" \
$PYTHON_BINARY -m poetry run pytest -v tests

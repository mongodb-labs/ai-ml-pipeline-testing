#!/bin/sh

# chat-gpt-retrieval-plugin is a poetry run project

set -x

. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# Install Poetry into base python
$PYTHON_BINARY -m pip install -U pip poetry
# Create a package specific poetry environment
$PYTHON_BINARY -m poetry env use $PYTHON_BINARY
# Activate the poetry env, which itself does not include poetry
source $($PYTHON_BINARY -m poetry env info --path)/bin/activate
# Recreate the poetry lock file
#$PYTHON_BINARY -m poetry lock
# Install from pyproject.toml into package specific environment
$PYTHON_BINARY -m poetry install --with dev

# Run tests. Sensitive variables in Evergreen come from Evergeen project: ai-ml-pipeline-testing/
OPENAI_API_KEY=$openai_api_key \
DATASTORE="mongodb" \
BEARER_TOKEN="staylowandkeepmoving" \
MONGODB_URI=$chatgpt_retrieval_plugin_mongodb_uri \
MONGODB_DATABASE="chatgpt_retrieval_plugin_test_db" \
MONGODB_COLLECTION="chatgpt_retrieval_plugin_test_vectorstore" \
MONGODB_INDEX="vector_index" \
EMBEDDING_MODEL="text-embedding-3-small" \
EMBEDDING_DIMENSION="1536" \
$PYTHON_BINARY -m poetry run pytest -v tests/datastore/providers/mongodb_atlas/

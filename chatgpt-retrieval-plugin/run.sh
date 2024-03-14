#!/bin/sh

echo ">>>>>>>>>> run.sh <<<<<<<<<<<<<<<"

# In this usage of poetry, we create a poetry env explicitly using python binary.

#set -x

. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3) # in utils.sh
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

$PYTHON_BINARY -m pip install -U pip

# Create a venv environment
$PYTHON_BINARY -m venv venv
# Activate the env
source venv/bin/activate
echo "$(which python)"

# Install dependencies. Pip will find poetry.dependencies.
python -m pip install poetry
python -m pip install .
# But pip will not find group.*.dependencies
python -m pip install httpx pytest pytest-cov pytest-asyncio

# Run tests, setting sensitive variables in Evergreen
OPENAI_API_KEY=$openai_api_key \
DATASTORE="mongodb" \
BEARER_TOKEN="staylowandkeepmoving" \
MONGODB_URI=$chatgpt_retrieval_plugin_mongodb_uri \
MONGODB_DATABASE="chatgpt_retrieval_plugin_test_db" \
MONGODB_COLLECTION="chatgpt_retrieval_plugin_test_vectorstore" \
MONGODB_INDEX="vector_index" \
EMBEDDING_MODEL="text-embedding-3-small" \
EMBEDDING_DIMENSION="1536" \
python -m pytest -v tests/datastore/providers/mongodb_atlas/

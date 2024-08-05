#!/bin/sh

# chat-gpt-retrieval-plugin is a poetry run project

set -x

. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# Create and activate an isolated python venv environment
$PYTHON_BINARY -m venv venv
source venv/bin/activate

python -m pip install -U pip poetry

# Recreate the poetry lock file
#python -m poetry lock --no-update
# Install from pyproject.toml into package specific environment
python -m poetry install --with dev

# Run tests. Sensitive variables in Evergreen come from Evergeen project: ai-ml-pipeline-testing/
OPENAI_API_KEY=$openai_api_key \
DATASTORE="mongodb-atlas" \
BEARER_TOKEN="staylowandkeepmoving" \
MONGODB_URI=$chatgpt_retrieval_plugin_mongodb_uri \
MONGODB_DATABASE="chatgpt_retrieval_plugin_test_db" \
MONGODB_COLLECTION="chatgpt_retrieval_plugin_test_vectorstore" \
MONGODB_INDEX="vector_index" \
EMBEDDING_MODEL="text-embedding-3-small" \
EMBEDDING_DIMENSION="1536" \
python -m poetry run pytest -v tests/datastore/providers/mongodb_atlas/

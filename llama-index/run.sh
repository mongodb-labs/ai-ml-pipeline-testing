#!/bin/sh

set -x

. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# cd to the MongoDB integration. It has its own project
cd llama-index-integrations/vector_stores/llama-index-vector-stores-mongodb

# Create and activate an isolated python venv environment
$PYTHON_BINARY -m venv venv
source venv/bin/activate

python -m pip install -U pip poetry

# Recreate the poetry lock file
python -m poetry lock --no-update
# Install from pyproject.toml into package specific environment
python -m poetry install --with dev


# Run tests. Sensitive variables in Evergreen come from Evergreen project: ai-ml-pipeline-testing/
OPENAI_API_KEY=$openai_api_key \
MONGODB_URI=$llama_index_mongodb_uri \
MONGODB_DATABASE="llama_index_test_db" \
MONGODB_COLLECTION="llama_index_test_vectorstore" \
MONGODB_INDEX="vector_index" \
$PYTHON_BINARY -m poetry run pytest -v tests

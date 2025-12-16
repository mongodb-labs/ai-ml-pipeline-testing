#!/bin/bash

set -eu

# Get the MONGODB_URI and AZURE_OPENAI_API_KEY.
SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $SCRIPT_DIR)
. $ROOT_DIR/env.sh

. $ROOT_DIR/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# cd to the MongoDB integration. It has its own project
# shellcheck disable=SC2164
cd llama-index-integrations/vector_stores/llama-index-vector-stores-mongodb

# Install uv.
$PYTHON_BINARY -m venv venv_pipeline
source venv_pipeline/bin/activate

export SSL_CERT_FILE=$($PYTHON_BINARY -c "import certifi; print(certifi.where())")

pip install -U pip
pip install uv

# Run tests.
UV_PYTHON=$PYTHON_BINARY \
MONGODB_DATABASE="llama_index_test_db" \
MONGODB_COLLECTION="llama_index_test_vectorstore" \
MONGODB_INDEX="vector_index" \
uv run pytest -v tests

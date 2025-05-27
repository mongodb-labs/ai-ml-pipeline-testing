#!/bin/bash

set -eu

# Get the MONGODB_URI and OPENAI_API_KEY.
SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $SCRIPT_DIR)
. $ROOT_DIR/env.sh

. $ROOT_DIR/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

$PYTHON_BINARY -m venv venv_pipeline
source venv_pipeline/bin/activate

pip install uv

uv sync --extra mongodb --extra test
uv run pytest tests/tools/test_mongodb_vector_search_tool.py


export MONGODB_URI=$MONGODB_URI
export OPENAI_API_KEY=$OPENAI_API_KEY

mv ../test_mongodb_vector_search_tool.py .
uv run python test_mongodb_vector_search_tool.py

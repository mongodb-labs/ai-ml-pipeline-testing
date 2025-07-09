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

uv sync --extra mongodb
uv run pytest -v tests/tools/test*mongodb*.py

mv ../test_mongodb_vector_search_tool.py .
uv run python test_mongodb_vector_search_tool.py

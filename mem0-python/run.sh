#!/bin/bash

set -eu

# Get the MONGODB_URI.
SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $SCRIPT_DIR)
. $ROOT_DIR/env.sh

. $ROOT_DIR/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

$PYTHON_BINARY -m venv venv_pipeline
source venv_pipeline/bin/activate

pip install hatch
make install_all

# Run tests.
export MONGODB_URI=$MONGODB_URI
pip install pytest
pip install .
pytest tests/vector_stores/test_mongodb.py

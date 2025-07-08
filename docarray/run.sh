#!/bin/bash

#  Sets up a virtual environment (poetry)
#  Runs the mongodb tests of the upstream repo

set -eu

# Get the MONGODB_URI.
SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $SCRIPT_DIR)

. $ROOT_DIR/env.sh

. $ROOT_DIR/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# Create and activate an isolated python venv environment
set -x
$PYTHON_BINARY -m venv venv
. venv/bin/activate
# Install Poetry
pip install -U pip poetry
# Recreate the poetry lock file
# poetry lock
# Install from pyproject.toml into package specific environment
poetry install --with dev --extras mongo
set +x

# Run tests. Sensitive variables in Evergreen come from Evergeen project: ai-ml-pipeline-testing/
# shellcheck disable=SC2154
export MONGODB_URI="$MONGODB_URI"
export MONGODB_DATABASE="docarray_test_db"
pytest -v tests/index/mongo_atlas || pytest --lf

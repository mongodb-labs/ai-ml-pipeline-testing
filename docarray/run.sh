#!/bin/sh

#  Sets up a virtual environment (poetry)
#  Runs the mongodb tests of the upstream repo

set -eu

# Get the MONGODB_URI.
SCRIPT_DIR=$(realpath $(dirname ${BASH_SOURCE[0]}))
ROOT_DIR=$(dirname $SCRIPT_DIR)

. $ROOT_DIR/env.sh

. $SCRIPT_DIR/utils.sh
PYTHON_BINARY=$(find_python3)
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# Create and activate an isolated python venv environment
$PYTHON_BINARY -m venv venv
. venv/bin/activate
# Install Poetry
pip install -U pip poetry
# Recreate the poetry lock file
poetry lock --no-update
# Install from pyproject.toml into package specific environment
poetry install --with dev --extras mongo


# Run tests. Sensitive variables in Evergreen come from Evergeen project: ai-ml-pipeline-testing/
# shellcheck disable=SC2154
MONGODB_URI="$MONGODB_URI" \
MONGODB_DATABASE="docarray_test_db" \
pytest -v tests/index/mongo_atlas

#!/bin/sh

#  Sets up a virtual environment (poetry)
#  Runs the mongodb tests of the upstream repo

set -x

. $workdir/src/.evergreen/utils.sh
PYTHON_BINARY=$(find_python3)
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# Create and activate an isolated python venv environment
$PYTHON_BINARY -m venv venv
source venv/bin/activate
# Install Poetry
pip install -U pip poetry
# Recreate the poetry lock file
poetry lock --no-update
# Install from pyproject.toml into package specific environment
poetry install --with dev --extras mongo


# Run tests. Sensitive variables in Evergreen come from Evergeen project: ai-ml-pipeline-testing/
MONGODB_URI=$docarray_mongodb_uri \
MONGODB_DATABASE="docarray_test_db" \
pytest -v tests/index/mongo_atlas

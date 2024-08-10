#!/bin/bash

# WORKING_DIR = src/langchain-python/langchain
set -x

. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

cd libs/partners/mongodb
# Create and activate an isolated python venv environment
$PYTHON_BINARY -m venv venv
source venv/bin/activate
# Install poetry
python -m pip install -U pip poetry
# Recreate the poetry lock file
python -m poetry lock --no-update
# Install from pyproject.toml into package specific environment
python -m poetry install --with lint --with typing --with codespell --with dev --with test --with test_integration
# Export env vars
export MONGODB_ATLAS_URI=$($atlas deployments connect $DIR --connectWith connectionString)
export OPENAI_API_KEY=$openai_api_key
# Run unit tests
make test
# Run integration tests
make integration_test

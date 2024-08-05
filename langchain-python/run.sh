#!/bin/bash

# WORKING_DIR = src/langchain-python/langchain
set -x

. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

cd libs/partners/mongodb

$PYTHON_BINARY -m venv venv
source venv/bin/activate

python -m poetry install --with lint --with typing --with codespell --with dev --with test --with test_integration

export MONGODB_ATLAS_URI=$($atlas deployments connect $DIR --connectWith connectionString)

make test

make integration_test

#!/bin/bash

# WORKING_DIR = src/langchain-python/langchain
set -x

. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

cd libs/partners/mongodb

$PYTHON_BINARY -m venv .
source ./bin/activate

pip install poetry

poetry install --with test
# Workaround provided in https://github.com/langchain-ai/langchain/issues/12237
# pip install build pyproject-hooks requests-toolbelt
# pip install --upgrade rapidfuzz filelock msgpack

make test

make integration_test
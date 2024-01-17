#!/bin/bash

# WORKING_DIR = src/langchain-python/langchain
set -x

cd libs/langchain


PYTHON_BINARY=/opt/python/3.10/bin/python3
$PYTHON_BINARY -m venv .
source ./bin/activate

pip install poetry
pip install filelock
pip install msgpack
pip install requests_toolbelt
pip install motor

poetry install --with test
# Workaround provided in https://github.com/langchain-ai/langchain/issues/12237
pip install build pyproject-hooks requests-toolbelt
pip install --upgrade rapidfuzz filelock msgpack

# Current hack to run just the mongo tests
TEST_FILE="tests/unit_tests -- -k mongo" make test

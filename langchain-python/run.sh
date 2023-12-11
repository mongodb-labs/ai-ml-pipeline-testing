#!/bin/bash

# WORKING_DIR = src/langchain-python/langchain
set -x

cd libs/langchain

pip install poetry
pip install rapidfuzz
pip install filelock
pip install msgpack
pip install requests_toolbelt
pip install motor
poetry install --with test

# Current hack to run just the mongo tests
TEST_FILE="tests/unit_tests -- -k mongo" make test

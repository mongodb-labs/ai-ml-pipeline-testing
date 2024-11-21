#!/bin/bash
set -eu

. .evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

# Should be called from src
EVERGREEN_PATH=$(pwd)/.evergreen
TARGET_DIR=$(pwd)/$DIR
SCAFFOLD_SCRIPT=$EVERGREEN_PATH/scaffold_atlas.py

mkdir atlas

setup_local_atlas

pushd atlas

$PYTHON_BINARY -m venv .
source ./bin/activate
popd

# Test server is up
$PYTHON_BINARY -m pip install pymongo
CONN_STRING=$CONN_STRING \
    $PYTHON_BINARY -c "from pymongo import MongoClient; import os; MongoClient(os.environ['CONN_STRING']).db.command('ping')"

# Add database and index configurations
DATABASE=$DATABASE \
    CONN_STRING=$CONN_STRING \
    REPO_NAME=$REPO_NAME \
    DIR=$DIR \
    DEBUG="${DEBUG:-1}" \
    TARGET_DIR=$TARGET_DIR \
    $PYTHON_BINARY $SCAFFOLD_SCRIPT

# Get the secrets.
source secrets-export.sh

# Create the env file
echo "export OPENAI_API_KEY=$OPENAI_API_KEY" >> env.sh
echo "export MONGODB_URI=$CONN_STRING" >> env.sh

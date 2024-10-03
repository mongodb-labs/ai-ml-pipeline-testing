#!/bin/bash

. .evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

# Should be called from src
EVERGREEN_PATH=$(pwd)/.evergreen
TARGET_DIR=$(pwd)/$DIR
SCAFFOLD_SCRIPT=$EVERGREEN_PATH/scaffold_atlas.py

set -ex
mkdir atlas

setup_local_atlas

cd atlas

$PYTHON_BINARY -m venv .
source ./bin/activate

# Test server is up
$PYTHON_BINARY -m pip install pymongo
CONN_STRING=$CONN_STRING \
    $PYTHON_BINARY -c "from pymongo import MongoClient; import os; MongoClient(os.environ['CONN_STRING']).db.command('ping')"

# Add database and index configurations
DATABASE=$DATABASE \
    CONN_STRING=$CONN_STRING \
    REPO_NAME=$REPO_NAME \
    DIR=$DIR \
    TARGET_DIR=$TARGET_DIR \
    $PYTHON_BINARY $SCAFFOLD_SCRIPT

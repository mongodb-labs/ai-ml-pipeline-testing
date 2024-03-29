#!/bin/bash

. .evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

# Should be called from src
EVERGREEN_PATH=$(pwd)/.evergreen
TARGET_DIR=$(pwd)/$DIR
PING_ATLAS=$EVERGREEN_PATH/ping_atlas.py
SCAFFOLD_SCRIPT=$EVERGREEN_PATH/scaffold_atlas.py
DEPLOYMENT_NAME=$DIR

# Download the mongodb tar and extract the binary into the atlas directory
set -ex
curl https://fastdl.mongodb.org/mongocli/mongodb-atlas-cli_1.18.0_linux_x86_64.tar.gz -o atlas.tgz
tar zxf atlas.tgz
mv mongodb-atlas-cli_1.18.0* atlas

# Create a local atlas deployment and store the connection string as an env var
$atlas deployments setup $DIR --type local --force --debug
$atlas deployments start $DIR
CONN_STRING=$($atlas deployments connect $DIR --connectWith connectionString)

# Make the atlas directory hold the virtualenv for provisioning
cd atlas

$PYTHON_BINARY -m venv .
source ./bin/activate

# Test server is up
$PYTHON_BINARY -m pip install pymongo
CONN_STRING=$CONN_STRING \
    $PYTHON_BINARY -c "from pymongo import MongoClient; import os; MongoClient(os.environ['CONN_STRING']).db.command('ping')"

# Add database configuration
DATABASE=$DATABASE \
    CONN_STRING=$CONN_STRING \
    REPO_NAME=$REPO_NAME \
    DIR=$DIR \
    TARGET_DIR=$TARGET_DIR \
    $PYTHON_BINARY $SCAFFOLD_SCRIPT

# If a search index configuration can be found, create the index
if [ -d "$TARGET_DIR/indexConfig.json" ]; then
    $atlas deployments search indexes create --file $TARGET_DIR/indexConfig.json --deploymentName $DIR
fi

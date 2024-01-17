#!/bin/bash

PYTHON_BINARY=/opt/python/3.10/bin/python3

# Should be called from src
EVERGREEN_PATH=$(pwd)/.evergreen
TARGET_DIR=$(pwd)/$DIR
PING_ATLAS=$EVERGREEN_PATH/ping_atlas.py
SCAFFOLD_SCRIPT=$EVERGREEN_PATH/scaffold_atlas.py
DEPLOYMENT_NAME=$DIR

# Download the mongodb tar and extract the binary into the atlas directory
# TODO: make this work for macos and linux
set -ex
curl https://fastdl.mongodb.org/mongocli/mongodb-atlas-cli_1.14.0_linux_x86_64.tar.gz -o atlas.tgz
tar zxf atlas.tgz
mv mongodb-atlas-cli_1.14.0* atlas

# Install Podman based on OS
set -Eeou pipefail
if [ -n "$(which yum 2>/dev/null)" ]; then
    sudo yum install -y podman
elif [ -n "$(which apt-get 2>/dev/null)" ]; then
    sudo apt-get update
    sudo apt-get install -y podman
elif [ -n "$(which zypper 2>/dev/null)" ]; then
    sudo zypper install -y podman
elif [ -n "$(which brew 2>/dev/null)" ]; then
    sudo brew install podman
fi

# Create a local atlas deployment and store the connection string as an env var
$atlas deployments setup $DIR --type local --force
$atlas deployments start $DIR
# TODO: make this env_var get stored in exapnsions.yml later
CONN_STRING=$($atlas deployments connect $DIR --connectWith connectionString)

# Make the atlas directory hold the virtualenv for provisioning
cd atlas

$PYTHON_BINARY -m venv .

# Test server is up
$PYTHON_BINARY -m pip install pymongo
CONN_STRING=$CONN_STRING \
    DATABASE=$DATABASE \
    COLLECTION="ping_collection" \
    $PYTHON_BINARY $PING_ATLAS

# Add database configuration
DATABASE=$DATABASE \
    CONN_STRING=$CONN_STRING \
    REPO_NAME=$REPO_NAME \
    DIR=$DIR \
    TARGET_DIR=$TARGET_DIR \
    $PYTHON_BINARY $SCAFFOLD_SCRIPT

# If an search index configuration can be found, set it
if [ -f "$TARGET_DIR/indexVector.json" ]; then
    $atlas deployments search indexes create --file $TARGET_DIR/indexVector.json --deploymentName $DIR
fi

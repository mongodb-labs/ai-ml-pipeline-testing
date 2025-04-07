#!/bin/bash

set -eu

find_python3() {
    PYTHON=""
    # Add a fallback system python3 if it is available and Python 3.7+.
    if is_python_310 "$(command -v python3)"; then
        PYTHON="$(command -v python3)"
    fi
    # Find a suitable toolchain version, if available.
    if [ "$(uname -s)" = "Darwin" ]; then
        # macos 11.00
        if [ -d "/Library/Frameworks/Python.Framework/Versions/3.10" ]; then
            PYTHON="/Library/Frameworks/Python.Framework/Versions/3.10/bin/python3"
        # macos 10.14
        elif [ -d "/Library/Frameworks/Python.Framework/Versions/3.7" ]; then
            PYTHON="/Library/Frameworks/Python.Framework/Versions/3.7/bin/python3"
        fi
    elif [ "Windows_NT" = "${OS:-}" ]; then # Magic variable in cygwin
        PYTHON="C:/python/Python37/python.exe"
    else
        # Prefer our own toolchain, fall back to mongodb toolchain if it has Python 3.7+.
        if [ -f "/opt/python/3.10/bin/python3" ]; then
            PYTHON="/opt/python/3.10/bin/python3"
        elif is_python_310 "$(command -v /opt/mongodbtoolchain/v4/bin/python3)"; then
            PYTHON="/opt/mongodbtoolchain/v4/bin/python3"
        elif is_python_310 "$(command -v /opt/mongodbtoolchain/v3/bin/python3)"; then
            PYTHON="/opt/mongodbtoolchain/v3/bin/python3"
        fi
    fi
    if [ -z "$PYTHON" ]; then
        echo "Cannot test without python3.10+ installed!"
        exit 1
    fi
    echo "$PYTHON"
}

# Function that returns success if the provided Python binary is version 3.7 or later
# Usage:
# is_python_310 /path/to/python
# * param1: Python binary
is_python_310() {
    if [ -z "$1" ]; then
        return 1
    elif $1 -c "import sys; exit(sys.version_info[:2] < (3, 10))"; then
        # runs when sys.version_info[:2] >= (3, 7)
        return 0
    else
        return 1
    fi
}



# start mongodb-atlas-local container, because of a bug in podman we have to define the healtcheck ourselves (is the same as in the image)
# stores the connection string in .local_atlas_uri file
setup_local_atlas() {
    SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
    # Ensure drivers-evergeen-tools checkout.
    pushd $SCRIPT_DIR/..
    git clone https://github.com/mongodb-labs/drivers-evergreen-tools || true
    . drivers-evergreen-tools/.evergreen/run-orchestration.sh --local-atlas
    popd
    echo "CONN_STRING=mongodb://127.0.0.1:27017/?directConnection=true" > $SCRIPT_DIR/.local_atlas_uri
}

fetch_local_atlas_uri() {
    SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
    . $SCRIPT_DIR/.local_atlas_uri

    export CONN_STRING=$CONN_STRING
    echo "$CONN_STRING"
}


scaffold_atlas() {
    PYTHON_BINARY=$(find_python3)

    EVERGREEN_PATH=$(realpath "$(dirname ${BASH_SOURCE[0]})")
    TARGET_DIR=$(pwd)/$DIR
    SCAFFOLD_SCRIPT=$EVERGREEN_PATH/scaffold_atlas.py

    mkdir -p atlas
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
}

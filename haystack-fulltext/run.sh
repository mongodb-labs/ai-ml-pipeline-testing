#!/bin/bash

# haystack-core-integrations is a hatch run project

set -eu

# Get the MONGODB_URI.
SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $SCRIPT_DIR)
. $ROOT_DIR/env.sh

. $ROOT_DIR/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# Installation
cd integrations/mongodb_atlas
$PYTHON_BINARY -m venv .venv
. .venv/bin/activate
PYTHON_BINARY=$(which python)
$PYTHON_BINARY -m pip install -U pip hatch

# Run tests.
MONGO_CONNECTION_STRING_2="$MONGODB_URI" hatch run test:all -v

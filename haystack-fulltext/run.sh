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
# certifi is used below, and is no longer a transitive dependency of hatch,
# which moved to truststore in 1.18.0. Install it explicitly.
# The click pin is a workaround for https://github.com/pypa/hatch/issues/2050
$PYTHON_BINARY -m pip install -U pip hatch certifi "click<8.3.0"

SSL_CERT_FILE=$($PYTHON_BINARY -c "import certifi; print(certifi.where())")
export SSL_CERT_FILE

# Run tests.
MONGO_CONNECTION_STRING_2="$MONGODB_URI" hatch run test:all -v

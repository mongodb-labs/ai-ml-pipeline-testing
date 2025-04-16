#!/bin/bash

set -eu

# Get the MONGODB_URI and VOYAGEAI_API_KEY.
SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $SCRIPT_DIR)
. $ROOT_DIR/env.sh

. $ROOT_DIR/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

$PYTHON_BINARY -m venv venv_pipeline
source venv_pipeline/bin/activate

pip install uv rust-just

just install

export MONGODB_URI=$MONGODB_URI
export VOYAGEAI_API_KEY=$VOYAGEAI_API_KEY

just test

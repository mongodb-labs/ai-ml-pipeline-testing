#!/bin/bash
set -eu

SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $(dirname $SCRIPT_DIR))

. $ROOT_DIR/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

$PYTHON_BINARY -m venv .venv

source .venv/bin/activate

pip install pymongo

python self_test.py
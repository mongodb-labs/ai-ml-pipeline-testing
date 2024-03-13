#!/bin/sh

set -x

. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3) # in utils.sh
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

$PYTHON_BINARY -m pip install poetry
poetry env use python3.10
source $(poetry env info --path)/bin/activate
poetry install --with dev

# Run Tests
poetry run pytest tests/datastore/providers/mongodb_atlas/





#!/bin/sh

set -x

. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3) # in utils.sh
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# Install Poetry into base python
$PYTHON_BINARY -m pip install poetry
# Create a package specific poetry environment
$PYTHON_BINARY -m poetry env use python3.10
# Activate the poetry env
source $($PYTHON_BINARY -m poetry env info --path)/bin/activate
# python3 is now that of the project-specific env
# Install requirements, including those for dev/test
python3 -m poetry install --with dev
# Run Tests
python3 -m poetry run pytest tests/datastore/providers/mongodb_atlas/

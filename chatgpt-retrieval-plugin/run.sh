#!/bin/sh

# In this usage of poetry, we install into a venv.
# Poetry recognizes that it is in a virtual environment so it's happy

set -x

. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3) # in utils.sh
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# Create and activate venv
$PYTHON_BINARY -m venv venv
source venv/bin/activate

# Install Poetry into venv.
# python3 is now that of the project-specific env
which python3
python3 -m pip install poetry

# Install requirements, including those for dev/test
python3 -m poetry install --with dev
# Run Tests
python3 -m poetry run pytest tests/datastore/providers/mongodb_atlas/

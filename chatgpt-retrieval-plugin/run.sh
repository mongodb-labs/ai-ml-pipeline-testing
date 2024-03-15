#!/bin/sh

echo ">>>>>>>>>> run.sh <<<<<<<<<<<<<<<"

# In this usage of poetry, we create a poetry env explicitly using python binary.

#set -x

. $workdir/src/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3) # in utils.sh
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# Install Poetry into base python
$PYTHON_BINARY -m pip install -U pip poetry
# Create a package specific poetry environment
$PYTHON_BINARY -m poetry env use $PYTHON_BINARY
# Activate the poetry env
source $($PYTHON_BINARY -m poetry env info --path)/bin/activate
# python3 is now that of the project-specific env
# Install requirements, including those for dev/test
$PYTHON_BINARY -m poetry lock
$PYTHON_BINARY -m poetry install --with dev


# Run tests, setting sensitive variables in Evergreen
OPENAI_API_KEY=$openai_api_key \
DATASTORE="mongodb" \
BEARER_TOKEN="staylowandkeepmoving" \
MONGODB_URI=$chatgpt_retrieval_plugin_mongodb_uri \
MONGODB_DATABASE="chatgpt_retrieval_plugin_test_db" \
MONGODB_COLLECTION="chatgpt_retrieval_plugin_test_vectorstore" \
MONGODB_INDEX="vector_index" \
EMBEDDING_MODEL="text-embedding-3-small" \
EMBEDDING_DIMENSION="1536" \
$PYTHON_BINARY -m poetry run pytest -v tests/datastore/providers/mongodb_atlas/

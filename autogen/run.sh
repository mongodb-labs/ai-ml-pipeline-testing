#!/bin/sh

#  Sets up a virtual environment
#  Runs the mongodb tests of the upstream repo
# NOTE: In this instance, the tests *programmtically* create_vector_search_index

set -x

. $workdir/src/.evergreen/utils.sh
PYTHON_BINARY=$(find_python3)
$PYTHON_BINARY -c "import sys; print(f'Python version found: {sys.version_info}')"

# Create and activate an isolated python venv environment
$PYTHON_BINARY -m venv venv
source venv/bin/activate
#  Install autogen with extras
$PYTHON_BINARY -m pip install .[test,"retrievechat-mongodb"]


# Run tests. Sensitive variables in Evergreen come from Evergreen project: ai-ml-pipeline-testing/
MONGODB_URI=$autogen_mongodb_uri \
MONGODB_DATABASE="autogen_test_db" \
pytest -v test/agentchat/contrib/vectordb/test_mongodb.py
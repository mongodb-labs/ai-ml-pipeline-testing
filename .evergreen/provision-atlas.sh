#!/bin/bash
set -eu

. .evergreen/utils.sh

setup_local_atlas
scaffold_atlas

# Get the secrets.
source secrets-export.sh

# Create the env file
echo "export OPENAI_API_KEY=$OPENAI_API_KEY" >> env.sh
echo "export MONGODB_URI=$CONN_STRING" >> env.sh

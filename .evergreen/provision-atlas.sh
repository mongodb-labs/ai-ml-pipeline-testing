#!/bin/bash
set -eu

. .evergreen/utils.sh

# Source the config
pushd $DIR
set -a
. config.env
set +x
popd

setup_local_atlas
scaffold_atlas

# Get the secrets.
source secrets-export.sh

# Create the env file
echo "export VOYAGEAI_S3_BUCKET=$VOYAGEAI_S3_BUCKET" >> env.sh
echo "export AZURE_OPENAI_ENDPOINT=$AZURE_OPENAI_ENDPOINT" >> env.sh
echo "export AZURE_OPENAI_API_KEY=$AZURE_OPENAI_API_KEY" >> env.sh
echo "export OPENAI_API_VERSION=$OPENAI_API_VERSION" >> env.sh
echo "export MONGODB_URI=$CONN_STRING" >> env.sh
echo "export VOYAGEAI_API_KEY=$VOYAGEAI_API_KEY" >> env.sh
echo "export COMMUNITY=${COMMUNITY-}" >> env.sh

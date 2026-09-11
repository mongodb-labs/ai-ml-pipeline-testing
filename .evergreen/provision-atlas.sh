#!/bin/bash
set -eu

. .evergreen/utils.sh

# Source the config
pushd $DIR
set -a
. config.env
set +x
popd

# Get the secrets. These must be sourced before setup_local_atlas, which passes
# VOYAGE_API_KEY into the atlas-local container when auto-embedding is enabled.
source secrets-export.sh
export VOYAGE_API_KEY=$VOYAGEAI_API_KEY

setup_local_atlas
scaffold_atlas

# Create the env file
echo "export DIR=$DIR" > env.sh
echo "export VOYAGEAI_S3_BUCKET=$VOYAGEAI_S3_BUCKET" >> env.sh
echo "export AZURE_OPENAI_ENDPOINT=$AZURE_OPENAI_ENDPOINT" >> env.sh
echo "export AZURE_OPENAI_API_KEY=$AZURE_OPENAI_API_KEY" >> env.sh
echo "export OPENAI_API_VERSION=$OPENAI_API_VERSION" >> env.sh
echo "export MONGODB_URI=$CONN_STRING" >> env.sh
echo "export VOYAGEAI_API_KEY=$VOYAGEAI_API_KEY" >> env.sh  # todo INTPYTHON-1097
echo "export VOYAGE_API_KEY=$VOYAGE_API_KEY" >> env.sh
echo "export COMMUNITY_WITH_SEARCH=${COMMUNITY_WITH_SEARCH-}" >> env.sh

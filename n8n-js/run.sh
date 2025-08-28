#! /bin/bash

set -o errexit
set -o xtrace

mkdir npm_global_dir
export NPM_CONFIG_PREFIX=$(pwd)/npm_global_dir
export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

npm i -g pnpm

# use node20
export PATH="/opt/devtools/node22/bin:/opt/dev/tools/bin:$PATH"

pnpm --version

pnpm install
pnpm build

# first, run the crud node tests
cd packages/nodes-base/nodes/MongoDb
pnpm test $(pwd)
cd -

# then, run the vector store tests
cd packages/@n8n/nodes-langchain/nodes/vector_store/VectorStoreMongoDBAtlas/
pnpm test $(pwd)
cd -

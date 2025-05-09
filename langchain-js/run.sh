#!/bin/bash

git branch
git switch use-local-atlas
git log -n 1

if [[ -f "env.sh" ]]; then
    source env.sh
fi

# setup node, npm and yarn
PATH=/opt/devtools/node22/bin:$(pwd)/bin:$PATH
npm_config_prefix=$(pwd)
export PATH
export npm_config_prefix

npm install --global yarn

bash ../../.evergreen/fetch-secrets.sh
source secrets-export.sh

cd libs/langchain-mongodb

yarn install
yarn build

yarn add --dev jest-junit
export JEST_JUNIT_OUTPUT_NAME=results.xml

if [[ -n "$MONGODB_URI" ]]; then
    export MONGODB_ATLAS_URI=$MONGODB_URI
fi

yarn test:int --reporters=default --reporters=jest-junit

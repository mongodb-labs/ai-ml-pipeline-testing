#!/bin/bash

git branch
git switch use-local-atlas
git log -n 1

if [[ -f "env.sh" ]]; then
    source env.sh
fi

# setup node, npm and yarn
export PATH=/opt/devtools/node22/bin:$PATH
export npm_config_prefix=$(pwd)
export PATH=$(pwd)/bin:$PATH
npm install --global yarn

bash ../../.evergreen/fetch-secrets.sh
source secrets-export.sh

cd libs/langchain-mongodb

yarn install
yarn build

yarn add --dev jest-junit
export JEST_JUNIT_OUTPUT_NAME=results.xml

yarn test:int --reporters=default --reporters=jest-junit

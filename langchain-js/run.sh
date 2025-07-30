#!/bin/bash
set -o errexit

setup_remote_atlas() {
    # Get the MONGODB_URI and OPENAI_API_KEY.
    SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
    ROOT_DIR=$(dirname $SCRIPT_DIR)

    if [[ -f "$ROOT_DIR/env.sh" ]]; then
        echo "Sourcing $ROOT_DIR/env.sh"
        source $ROOT_DIR/env.sh
    fi

    bash "$ROOT_DIR/.evergreen/fetch-secrets.sh"
    source secrets-export.sh

    if [[ -n "$MONGODB_URI" ]]; then
        export MONGODB_ATLAS_URI=$MONGODB_URI
    fi
}

setup_node_and_yarn() {
    # setup node, npm and yarn
    PATH=/opt/devtools/node22/bin:$(pwd)/bin:$PATH
    npm_config_prefix=$(pwd)
    export PATH
    export npm_config_prefix

    npm install --global yarn
}

setup_langchain_integration() {
    cd libs/langchain-mongodb

    yarn install
    yarn build

    yarn add --dev jest-junit
    export JEST_JUNIT_OUTPUT_NAME=results.xml
    # Trim trailing slashes since lanchainjs is doing string manipulationn, not
    # using the URI class.
    export AZURE_OPENAI_BASE_PATH=$(echo "$$AZURE_OPENAI_ENDPOINT" | sed 's:/*$::')
    export AZURE_OPENAI_API_VERSION=$OPENAI_API_VERSION
    # optionally enable to debug local atlas in CI.
    # export DEBUG=testcontainers*
}

setup_remote_atlas
setup_node_and_yarn
setup_langchain_integration

yarn test:int --reporters=default --reporters=jest-junit

#!/bin/bash
set -o errexit

setup_node_and_pnpm() {
    # setup node, npm and pnpm
    PATH=/opt/devtools/node22/bin:$(pwd)/bin:$PATH
    npm_config_prefix=$(pwd)
    export PATH
    export npm_config_prefix

    npm install -g pnpm@latest-10
    npm install --global corepack --force
    corepack enable
}

build_mastra_workspace() {
    pnpm install

    # Building the mongodb store and rag packages also builds their
    # workspace dependencies (e.g. @mastra/core), per turbo's build
    # task graph (`dependsOn: ["^build"]` in turbo.json).
    pnpm turbo --filter "@mastra/mongodb" build
    pnpm turbo --filter "@mastra/rag" build
}

run_mongodb_store_tests() {
    # `pnpm test` here also runs the package's pretest/posttest hooks,
    # which bring up and tear down the local MongoDB containers this
    # store's tests connect to (see stores/mongodb/docker-compose.yaml).
    (
        cd stores/mongodb
        pnpm test --reporter=default --reporter=junit --outputFile=./results-mongodb.xml
    )
}

run_rag_database_config_tests() {
    (
        cd packages/rag
        pnpm vitest run src/tools/vector-query-database-config.test.ts \
            --reporter=default --reporter=junit --outputFile=./results-rag.xml
    )
}

setup_node_and_pnpm
build_mastra_workspace
run_mongodb_store_tests
run_rag_database_config_tests

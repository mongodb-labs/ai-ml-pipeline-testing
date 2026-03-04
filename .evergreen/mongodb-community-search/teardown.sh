#!/bin/bash

set -eu

pushd "$(dirname ${BASH_SOURCE:-$0})" > /dev/null
docker compose down || true
popd > /dev/null

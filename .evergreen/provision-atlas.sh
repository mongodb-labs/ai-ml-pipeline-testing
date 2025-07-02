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

echo "export MONGODB_URI=$CONN_STRING" > env.sh

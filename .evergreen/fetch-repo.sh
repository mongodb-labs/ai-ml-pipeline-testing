#!/bin/bash

set -eu

if [ ! -d "${DIR}" ]; then
  echo '${REPO_NAME} could not be found' 1>&2
  exit 1
fi

cd ${DIR}

# Source the configuration.
set -a
source config.env
set +a

rm -rf ${REPO_NAME}
git clone ${CLONE_URL}

# Apply patches to upstream repo if desired.
if [ -d "patches" ]; then
  cd ${REPO_NAME}
  echo "Applying patches."
  git apply ../patches/*
fi

#!/bin/bash

set -eu

# Check if a branch parameter is provided
BRANCH=""
if [ $# -gt 0 ]; then
  BRANCH=$1
fi

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

# Clone the repository, with an optional branch
if [ -n "${BRANCH}" ]; then
  git clone --branch "${BRANCH}" "${CLONE_URL}"
else
  git clone "${CLONE_URL}"
fi

# Apply patches to upstream repo if desired.
if [ -d "patches" ]; then
  cd ${REPO_NAME}
  echo "Applying patches."
  git apply ../patches/*
fi

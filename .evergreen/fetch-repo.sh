#!/bin/bash

set -eu

if [ ! -d "${DIR}" ]; then
  echo "${REPO_NAME} could not be found" 1>&2
  exit 1
fi

cd ${DIR}

# Allow overrides from the patch build.
REPO_ORG_OVERRIDE=${REPO_ORG:-}
REPO_BRANCH_OVERRIDE=${REPO_BRANCH:-}

# Source the configuration.
set -a
source config.env
set +a

if [ -n "${REPO_ORG_OVERRIDE}" ]; then
  REPO_ORG="${REPO_ORG_OVERRIDE}"
fi
if [ -n "${REPO_BRANCH_OVERRIDE}" ]; then
  REPO_BRANCH="${REPO_BRANCH_OVERRIDE}"
fi

rm -rf ${REPO_NAME}

ARGS="https://github.com/${REPO_ORG}/${REPO_NAME}"
if [ -n "${REPO_BRANCH:-}" ]; then
  ARGS="-b ${REPO_BRANCH} ${ARGS}"
fi

echo "Cloning repo $ARGS..."
git clone --depth=1 ${ARGS}
echo "Cloning repo $ARGS... done."

# Apply patches to upstream repo if desired.
if [ -d "patches" ]; then
  cd ${REPO_NAME}
  echo "Applying patches."
  git apply ../patches/*
fi

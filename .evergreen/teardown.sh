#!/bin/bash

set -eu

if [ -n "${REPO_ORG_OVERRIDE}" ]; then
  echo "REPO_ORG=$REPO_ORG_OVERRIDE"
fi
if [ -n "${REPO_BRANCH_OVERRIDE}" ]; then
  echo "REPO_BRANCH=$REPO_BRANCH_OVERRIDE"
fi

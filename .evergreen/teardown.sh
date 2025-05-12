#!/bin/bash

set -eu

if [ -n "${REPO_ORG:-}" ]; then
  echo "REPO_ORG=$REPO_ORG"
fi
if [ -n "${REPO_BRANCH:-}" ]; then
  echo "REPO_BRANCH=$REPO_BRANCH"
fi

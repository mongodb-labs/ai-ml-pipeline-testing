#!/bin/bash

set -eu

OVERRIDES=
if [ -n "${REPO_ORG:-}" ]; then
  echo "REPO_ORG=$REPO_ORG"
  OVERRIDES=1
fi
if [ -n "${REPO_BRANCH:-}" ]; then
  echo "REPO_BRANCH=$REPO_BRANCH"
  OVERRIDES=1
fi

if [ -z "${OVERRIDES}" ]; then
  echo "No overrides"
fi

#!/bin/bash

set -eu

# Clone drivers-evergeen-tools.
if [ ! -d drivers-evergreen-tools ]; then
  git clone https://github.com/mongodb-labs/drivers-evergreen-tools
fi

# Get the secrets for drivers/ai-ml-pipeline-testing.
. drivers-evergreen-tools/.evergreen/secrets_handling/setup-secrets.sh drivers/ai-ml-pipeline-testing
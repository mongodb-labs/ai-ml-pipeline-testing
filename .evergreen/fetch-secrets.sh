#!/bin/bash

set -eu

# Clone drivers-evergeen-tools.
git clone --branch fix-podman-setup https://github.com/blink1073/drivers-evergreen-tools

# Get the secrets for drivers/ai-ml-pipeline-testing.
. drivers-evergreen-tools/.evergreen/secrets_handling/setup-secrets.sh drivers/ai-ml-pipeline-testing

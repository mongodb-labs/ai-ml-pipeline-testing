#!/bin/bash

set -eu

# WORKING_DIR = $ROOT_DIR/semantic-kernel-csharp/semantic-kernel

# Install .NET
DOTNET_SDK_PATH=./.dotnet
mkdir -p "$DOTNET_SDK_PATH"

echo "Downloading .NET SDK installer into $DOTNET_SDK_PATH folder..."
curl -Lfo "$DOTNET_SDK_PATH"/dotnet-install.sh https://dot.net/v1/dotnet-install.sh
echo "Installing .NET LTS SDK..."
bash "$DOTNET_SDK_PATH"/dotnet-install.sh --channel 9.0 --install-dir "$DOTNET_SDK_PATH" --no-path

# The tests use the TestContainers.Net library which requires docker.
# RHEL 8 and 9 don't support docker so we have the setup below to emulate docker with podman
sudo dnf install -y docker

# Enable and start Podman's socket service to listen for Docker API calls
sudo systemctl enable --now podman.socket

# Point docker commands to use the podman socket
export DOCKER_HOST="unix:///run/podman/podman.sock"

# Set SkipReason to null to enable tests
sed -i -e 's/"The MongoDB container is intermittently timing out at startup time blocking prs, so these test should be run manually."/null/g' dotnet/src/IntegrationTests/Connectors/Memory/MongoDB/MongoDBVectorStoreRecordCollectionTests.cs

# Remove the attribute blocking tests so we can run them
sed -i -e 's/\[DisableVectorStoreTests(Skip = "The MongoDB container is intermittently timing out at startup time blocking prs, so these test should be run manually.")\]//g' dotnet/src/IntegrationTests/Connectors/Memory/MongoDB/MongoDBVectorStoreTests.cs

echo "Running MongoDBVectorStoreTests and MongoDBVectorStoreRecordCollectionTests"
sudo $DOTNET_SDK_PATH/dotnet test dotnet/src/IntegrationTests/IntegrationTests.csproj --filter "SemanticKernel.IntegrationTests.Connectors.MongoDB.MongoDBVectorStoreTests | SemanticKernel.IntegrationTests.Connectors.MongoDB.MongoDBVectorStoreRecordCollectionTests"

#!/bin/bash

set -eu

# WORKING_DIR = $ROOT_DIR/semantic-kernel-csharp/semantic-kernel

# Install .NET
DOTNET_SDK_PATH=./.dotnet
mkdir -p "$DOTNET_SDK_PATH"

echo "Downloading .NET SDK installer into $DOTNET_SDK_PATH folder..."
curl -Lfo "$DOTNET_SDK_PATH"/dotnet-install.sh https://dot.net/v1/dotnet-install.sh
echo "Installing .NET 9.0 SDK..."
bash "$DOTNET_SDK_PATH"/dotnet-install.sh --channel 9.0 --install-dir "$DOTNET_SDK_PATH" --no-path
echo "Installing .NET 8.0 runtime..."
bash "$DOTNET_SDK_PATH"/dotnet-install.sh --channel 8.0 --install-dir "$DOTNET_SDK_PATH" --no-path --runtime dotnet

# The tests use the TestContainers.Net library which requires docker.
# RHEL 8 and 9 don't support docker so we have the setup below to emulate docker with podman
sudo dnf install -y docker

# Enable and start Podman's socket service to listen for Docker API calls
sudo systemctl enable --now podman.socket

# Point docker commands to use the podman socket
export DOCKER_HOST="unix:///run/podman/podman.sock"

# Enable MongoDB.ConformanceTests
sed -i -e '/\[assembly: DisableTests/d' dotnet/test/VectorData/MongoDB.ConformanceTests/Properties/AssemblyInfo.cs

# Export the MongoDB connection string
export MONGODB__CONNECTIONURL=$MONGODB_URI

echo "Running MongoDB.ConformanceTests"
sudo $DOTNET_SDK_PATH/dotnet test dotnet/test/VectorData/MongoDB.ConformanceTests/MongoDB.ConformanceTests.csproj --framework net8.0

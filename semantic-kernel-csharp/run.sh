#!/bin/bash

set -eu

# Get the MONGODB_URI
SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $SCRIPT_DIR)
. $ROOT_DIR/env.sh

. $ROOT_DIR/.evergreen/utils.sh

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

# Enable MongoDB.ConformanceTests
sed -i -e '/\[assembly: DisableTests/d' dotnet/test/VectorData/MongoDB.ConformanceTests/Properties/AssemblyInfo.cs

# Export the MongoDB connection string
export MONGODB__CONNECTIONURL=$MONGODB_URI

# Run tests
echo "Running MongoDB.ConformanceTests"
$DOTNET_SDK_PATH/dotnet test dotnet/test/VectorData/MongoDB.ConformanceTests/MongoDB.ConformanceTests.csproj --framework net8.0

#!/bin/bash

set -x

# WORKING_DIR = src/semantic-kernel-csharp/semantic-kernel

# Install .NET
DOTNET_SDK_PATH=./.dotnet
mkdir -p "$DOTNET_SDK_PATH"

echo "Downloading .NET SDK installer into $DOTNET_SDK_PATH folder..."
curl -Lfo "$DOTNET_SDK_PATH"/dotnet-install.sh https://dot.net/v1/dotnet-install.sh
echo "Installing .NET LTS SDK..."
bash "$DOTNET_SDK_PATH"/dotnet-install.sh --channel 6.0 --install-dir "$DOTNET_SDK_PATH" --no-path

# Set SkipReason to null to enable tests
sed -i -e 's/"MongoDB Atlas cluster is required"/null/g' dotnet/src/IntegrationTests/Connectors/Memory/MongoDB/MongoDBMemoryStoreTests.cs

# Run tests
echo "Running MongoDBMemoryStoreTests"
# Stored in evergreen VARIABLES
<<<<<<< HEAD
MongoDB__ConnectionString=$($atlas deployments connect $DIR --connectWith connectionString) \
=======
MongoDB__ConnectionString=$semantic_kernel_mongodb_uri \
>>>>>>> f793c95 (CSHARP: Integration tests for .NET SK memory connector)
$DOTNET_SDK_PATH/dotnet test dotnet/src/IntegrationTests/IntegrationTests.csproj --filter SemanticKernel.IntegrationTests.Connectors.MongoDB.MongoDBMemoryStoreTests
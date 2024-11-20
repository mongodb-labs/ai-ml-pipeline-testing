#!/bin/bash
set -eu

# source secrets-export.sh

if [ -z "${DIR:-}" ]; then
    echo "Must give a target dir!"
    exit 1
fi

# Get the correct remote URI.
case $DIR in
    llama-index-python-kvstore)
        MONGODB_URI=$llama_index_mongodb_uri
    ;;
    semantic-kernel-python)
        MONGODB_URI=$semantic_kernel_mongodb_uri
    ;;
    semantic-kernel-csharp)
        MONGODB_URI=$semantic_kernel_mongodb_uri
    ;;
    langchain-python)
        MONGODB_URI=$docarray_mongodb_uri
    ;;
    chatgpt-retrieval-plugin)
        MONGODB_URI=$chatgpt_retrieval_plugin_mongodb_uri
    ;;
    llama-index-python-vectorstore)
        MONGODB_URI=$llama_index_mongodb_uri
    ;;
    docarray)
        MONGODB_URI=$docarray_mongodb_uri
    ;;
    *)
        echo "Missing config in fetch-secrets.sh for DIR: $DIR"
        exit 1
    ;;
esac

# Create the env file
echo "export OPENAI_API_KEY=$openai_api_key" >> env.sh
echo "export MONGODB_URI=$MONGODB_URI" >> env.sh

echo "set MONGODB_URI=$MONGODB_URI"
exit 1

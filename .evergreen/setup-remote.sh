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
        MONGODB_URI=$LLAMA_INDEX_MONGODB_URI
    ;;
    semantic-kernel-python)
        MONGODB_URI=$SEMANTIC_KERNEL_MONGODB_URI
    ;;
    semantic-kernel-csharp)
        MONGODB_URI=$SEMANTIC_KERNEL_MONGODB_URI
    ;;
    langchain-python)
        MONGODB_URI=$LANGCHAIN_MONGODB_URI
    ;;
    chatgpt-retrieval-plugin)
        MONGODB_URI=$CHATGPT_RETRIEVAL_PLUGIN_MONGODB_URI
    ;;
    llama-index-python-vectorstore)
        MONGODB_URI=$LLAMA_INDEX_MONGODB_URI
    ;;
    docarray)
        MONGODB_URI=$DOCARRAY_MONGODB_URI
    ;;
    *)
        echo "Missing config in fetch-secrets.sh for DIR: $DIR"
        exit 1
    ;;
esac

# Create the env file
echo "export OPENAI_API_KEY=$openai_api_key" >> env.sh
echo "export MONGODB_URI=$MONGODB_URI" >> env.sh

#!/bin/bash
set -eu

source secrets-export.sh

if [ -z "${DIR:-}" ]; then
    echo "Must give a target dir!"
    exit 1
fi

# Source the config
pushd $DIR
set -a
. config.env
set +x
popd

# Get the correct remote URI.
case $DIR in
    semantic-kernel-python)
        MONGODB_URI=$SEMANTIC_KERNEL_MONGODB_URI
    ;;
    semantic-kernel-csharp)
        MONGODB_URI=$SEMANTIC_KERNEL_MONGODB_URI
    ;;
    langchain-python | langgraph-python)
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
    haystack-embeddings | haystack-fulltext)
        MONGODB_URI=$HAYSTACK_MONGODB_URI
    ;;
    pymongo-voyageai)
        MONGODB_URI=$VOYAGEAI_MONGODB_URI
    ;;
    *)
        echo "Missing config in setup-remote.sh for DIR: $DIR"
        exit 1
    ;;
esac
export MONGODB_URI

# Create the env file
echo "export VOYAGEAI_S3_BUCKET=$VOYAGEAI_S3_BUCKET" >> env.sh
echo "export VOYAGEAI_API_KEY=$VOYAGEAI_API_KEY" >> env.sh
echo "export OPENAI_API_KEY=$OPENAI_API_KEY" >> env.sh
echo "export MONGODB_URI=$MONGODB_URI" >> env.sh

# Ensure the remote database is populated.
. .evergreen/utils.sh

CONN_STRING=$MONGODB_URI scaffold_atlas

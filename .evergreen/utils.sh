#!/bin/bash

set -eu

find_python3() {
    PYTHON=""
    # Add a fallback system python3 if it is available and Python 3.7+.
    if is_python_310 "$(command -v python3)"; then
        PYTHON="$(command -v python3)"
    fi
    # Find a suitable toolchain version, if available.
    if [ "$(uname -s)" = "Darwin" ]; then
        # macos 11.00
        if [ -d "/Library/Frameworks/Python.Framework/Versions/3.10" ]; then
            PYTHON="/Library/Frameworks/Python.Framework/Versions/3.10/bin/python3"
        # macos 10.14
        elif [ -d "/Library/Frameworks/Python.Framework/Versions/3.7" ]; then
            PYTHON="/Library/Frameworks/Python.Framework/Versions/3.7/bin/python3"
        fi
    elif [ "Windows_NT" = "${OS:-}" ]; then # Magic variable in cygwin
        PYTHON="C:/python/Python37/python.exe"
    else
        # Prefer our own toolchain, fall back to mongodb toolchain if it has Python 3.7+.
        if [ -f "/opt/python/3.10/bin/python3" ]; then
            PYTHON="/opt/python/3.10/bin/python3"
        elif is_python_310 "$(command -v /opt/mongodbtoolchain/v4/bin/python3)"; then
            PYTHON="/opt/mongodbtoolchain/v4/bin/python3"
        elif is_python_310 "$(command -v /opt/mongodbtoolchain/v3/bin/python3)"; then
            PYTHON="/opt/mongodbtoolchain/v3/bin/python3"
        fi
    fi
    if [ -z "$PYTHON" ]; then
        echo "Cannot test without python3.10+ installed!"
        exit 1
    fi
    echo "$PYTHON"
}

# Function that returns success if the provided Python binary is version 3.7 or later
# Usage:
# is_python_310 /path/to/python
# * param1: Python binary
is_python_310() {
    if [ -z "$1" ]; then
        return 1
    elif $1 -c "import sys; exit(sys.version_info[:2] < (3, 10))"; then
        # runs when sys.version_info[:2] >= (3, 7)
        return 0
    else
        return 1
    fi
}



# Start the mongodb-atlas-local container ourselves, with auto-embedding enabled.
#
# This duplicates what drivers-evergreen-tools' run-orchestration.sh --local-atlas
# does, because DET builds a fixed `docker run` argv and offers no way to forward
# environment into the container (see start_atlas in
# drivers-evergreen-tools/.evergreen/orchestration/drivers_orchestration.py).
# The atlas-local image reads VOYAGE_API_KEY to register Voyage auto-embedding
# models; without it mongot reports
# "CanonicalModel: <model> not registered yet, supported models are: []".
#
# Voyage serves embeddings from two hosts, and each only accepts keys issued by
# that host. Set EMBEDDING_PROVIDER_ENDPOINT to https://api.voyageai.com/v1/embeddings
# for a key from voyageai.com; leave it unset for a key from mongodb.com, which
# uses the image's built-in default (ai.mongodb.com).
#
# Delete this in favour of run-orchestration.sh once DET supports env passthrough.
start_atlas_local_autoembed() {
    local version="$1"
    local script_dir
    script_dir=$(realpath "$(dirname ${BASH_SOURCE[0]})")
    local det_dir="$script_dir/../drivers-evergreen-tools/.evergreen"
    local image="mongodb/mongodb-atlas-local:${version}"

    local docker_cmd
    if command -v docker > /dev/null; then
        docker_cmd=docker
    elif command -v podman > /dev/null; then
        docker_cmd=podman
    else
        echo "Docker/Podman is required for local atlas but was not found!"
        exit 1
    fi

    if [ -z "${VOYAGE_API_KEY:-}" ]; then
        echo "ATLAS_LOCAL_AUTO_EMBED is set but VOYAGE_API_KEY is empty."
        echo "Source secrets-export.sh before calling setup_local_atlas."
        exit 1
    fi

    # Tear down anything left from a previous run.
    bash $det_dir/stop-orchestration.sh || true
    $docker_cmd rm -f mongodb_atlas_local > /dev/null 2>&1 || true

    local hub_image="$image"

    # On Evergreen, authenticate to and pull through the ECR mirror.
    if [ -n "${CI:-}" ] && [ -z "${GITHUB_ACTION:-}" ]; then
        bash $det_dir/docker/setup.sh
        image="901841024863.dkr.ecr.us-east-1.amazonaws.com/dockerhub/${image}"
    fi

    # Fall back to Docker Hub, where these tags are public.
    if ! $docker_cmd pull "$image"; then
        if [ "$image" = "$hub_image" ]; then
            echo "Failed to pull ${image}!"
            exit 1
        fi
        echo "Failed to pull ${image} from the ECR mirror, falling back to Docker Hub."
        image="$hub_image"
        $docker_cmd pull "$image"
    fi

    # Podman does not pick up the image's HEALTHCHECK, so declare it explicitly.
    local health_args=()
    if [ "$docker_cmd" = "podman" ]; then
        health_args=(--health-cmd "/usr/local/bin/runner healthcheck")
    fi

    # An unset endpoint means "use the image default", so only forward it when set.
    local endpoint_args=()
    if [ -n "${EMBEDDING_PROVIDER_ENDPOINT:-}" ]; then
        endpoint_args=(-e EMBEDDING_PROVIDER_ENDPOINT="$EMBEDDING_PROVIDER_ENDPOINT")
    fi

    # Each host only accepts its own keys, and a mismatch fails silently: index
    # creation succeeds, then mongot retries a 403 forever and the index never
    # leaves INITIAL_SYNC. That surfaces much later as an index timeout, so
    # check the key prefix against the endpoint here and fail fast instead.
    local expected_prefix=""
    case "${EMBEDDING_PROVIDER_ENDPOINT:-ai.mongodb.com}" in
        *api.voyageai.com*) expected_prefix="pa-" ;;   # keys issued by voyageai.com
        *ai.mongodb.com*)   expected_prefix="al-" ;;   # keys issued by mongodb.com
        *) echo "Warning: unrecognized EMBEDDING_PROVIDER_ENDPOINT, skipping key check." ;;
    esac
    if [ -n "$expected_prefix" ] && [ "${VOYAGE_API_KEY#$expected_prefix}" = "$VOYAGE_API_KEY" ]; then
        echo "VOYAGE_API_KEY does not match the configured embedding endpoint!"
        echo "Keys from voyageai.com begin with 'pa-' and require"
        echo "EMBEDDING_PROVIDER_ENDPOINT=https://api.voyageai.com/v1/embeddings;"
        echo "keys from mongodb.com begin with 'al-' and require it to be unset."
        exit 1
    fi

    echo "Starting ${image} with auto-embedding (endpoint ${EMBEDDING_PROVIDER_ENDPOINT:-ai.mongodb.com, image default})..."
    local container_id
    container_id=$($docker_cmd run --rm -d \
        --name mongodb_atlas_local \
        -p 27017:27017 \
        -e VOYAGE_API_KEY="$VOYAGE_API_KEY" \
        ${endpoint_args[@]+"${endpoint_args[@]}"} \
        ${health_args[@]+"${health_args[@]}"} \
        -P "$image")

    # stop-orchestration.sh stops the container id recorded in this file.
    mkdir -p $det_dir/orchestration
    echo "$container_id" > $det_dir/orchestration/container_id.txt

    echo "Waiting for container to be healthy..."
    local tries=0
    local status=""
    while [ "$status" != "healthy" ]; do
        if [ $tries -ge 60 ]; then
            echo "Timed out waiting for container to become healthy!"
            $docker_cmd logs "$container_id" || true
            exit 1
        fi
        sleep 1
        tries=$((tries + 1))
        status=$($docker_cmd inspect -f '{{.State.Health.Status}}' "$container_id" 2>/dev/null || echo "")
    done
    echo "Waiting for container to be healthy... done."
}


# start mongodb-atlas-local container, because of a bug in podman we have to define the healthcheck ourselves (is the same as in the image)
# stores the connection string in .local_atlas_uri file
#
# The mongodb/mongodb-atlas-local image tag is selected by ATLAS_LOCAL_VERSION
# (default "latest"), either as the first argument or from the environment, e.g.
#   setup_local_atlas preview
#   ATLAS_LOCAL_VERSION=preview setup_local_atlas
# drivers-evergreen-tools uses MONGODB_VERSION as the image tag for --local-atlas,
# and its env vars take precedence over its CLI flags, so we export it for the call.
#
# If ATLAS_LOCAL_AUTO_EMBED is set (see the project's config.env), the container
# is started by start_atlas_local_autoembed instead, which is the only path that
# can enable Voyage auto-embedding. Requires ATLAS_LOCAL_VERSION=preview.
setup_local_atlas() {
    SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
    local atlas_local_version="${1:-${ATLAS_LOCAL_VERSION:-latest}}"
    # Ensure drivers-evergeen-tools checkout.
    pushd $SCRIPT_DIR/..
    git clone https://github.com/mongodb-labs/drivers-evergreen-tools || true
    popd
    if [ -z "${COMMUNITY_WITH_SEARCH:-}" ]; then
        bash $SCRIPT_DIR/mongodb-community-search/teardown.sh
        if [ -n "${ATLAS_LOCAL_AUTO_EMBED:-}" ]; then
            start_atlas_local_autoembed "$atlas_local_version"
        else
            echo "Starting mongodb/mongodb-atlas-local:${atlas_local_version}..."
            MONGODB_VERSION="$atlas_local_version" \
                bash $SCRIPT_DIR/../drivers-evergreen-tools/.evergreen/run-orchestration.sh --local-atlas -v
        fi
    else
        if [ -n "${CI:-}" ]; then
            bash $SCRIPT_DIR/../drivers-evergreen-tools/.evergreen/docker/setup.sh
        fi
        bash $SCRIPT_DIR/../drivers-evergreen-tools/.evergreen/stop-orchestration.sh
        bash $SCRIPT_DIR/mongodb-community-search/start-services.sh
    fi
    export CONN_STRING"=mongodb://127.0.0.1:27017/?directConnection=true"
    echo "CONN_STRING=$CONN_STRING" > $SCRIPT_DIR/.local_atlas_uri
}

fetch_local_atlas_uri() {
    SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
    . $SCRIPT_DIR/.local_atlas_uri

    export CONN_STRING=$CONN_STRING
    echo "$CONN_STRING"
}


scaffold_atlas() {
    PYTHON_BINARY=$(find_python3)

    EVERGREEN_PATH=$(realpath "$(dirname ${BASH_SOURCE[0]})")
    TARGET_DIR=$(pwd)/$DIR
    SCAFFOLD_SCRIPT=$EVERGREEN_PATH/scaffold_atlas.py

    mkdir -p atlas
    pushd atlas

    $PYTHON_BINARY -m venv .
    source ./bin/activate
    popd

    # Test server is up
    $PYTHON_BINARY -m pip install pymongo
    CONN_STRING=$CONN_STRING \
        $PYTHON_BINARY -c "from pymongo import MongoClient; import os; MongoClient(os.environ['CONN_STRING']).db.command('ping')"

    # Add database and index configurations
    DATABASE=$DATABASE \
        CONN_STRING=$CONN_STRING \
        REPO_NAME=$REPO_NAME \
        DIR=$DIR \
        DEBUG="${DEBUG:-1}" \
        TARGET_DIR=$TARGET_DIR \
        $PYTHON_BINARY $SCAFFOLD_SCRIPT
}

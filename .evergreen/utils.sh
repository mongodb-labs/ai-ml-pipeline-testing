#!/bin/bash -ex

set -o xtrace

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


retry() {
    for i in 1 2 4 8 16; do
        { "$@" && return 0; } || sleep $i
    done
    return 1
}


# start mongodb-atlas-local container, because of a bug in podman we have to define the healtcheck ourselves (is the same as in the image)
# stores the connection string in .local_atlas_uri file
setup_local_atlas() {
    echo "Starting the container"

    IMAGE=artifactory.corp.mongodb.com/dockerhub/mongodb/mongodb-atlas-local:latest
    retry podman pull $IMAGE

    CONTAINER_ID=$(podman run --rm -d -e DO_NOT_TRACK=1 -P --health-cmd "/usr/local/bin/runner healthcheck" mongodb/mongodb-atlas-local:latest)

    echo "waiting for container to become healthy..."
    function wait() {
    CONTAINER_ID=$1
    echo "waiting for container to become healthy..."
    podman healthcheck run "$CONTAINER_ID"
    for _ in $(seq 600); do
        STATE=$(podman inspect -f '{{ .State.Health.Status }}' "$CONTAINER_ID")

        case $STATE in
            healthy)
            echo "container is healthy"
            return 0
            ;;
            unhealthy)
            echo "container is unhealthy"
            podman logs "$CONTAINER_ID"
            stop
            exit 1
            ;;
            *)
            echo "Unrecognized state $STATE"
            sleep 1
        esac
    done

    echo "container did not get healthy within 120 seconds, quitting"
    podman logs mongodb_atlas_local
    stop
    exit 2
    }

    wait "$CONTAINER_ID"
    EXPOSED_PORT=$(podman inspect --format='{{ (index (index .NetworkSettings.Ports "27017/tcp") 0).HostPort }}' "$CONTAINER_ID")
    export CONN_STRING="mongodb://127.0.0.1:$EXPOSED_PORT/?directConnection=true"
    # shellcheck disable=SC2154
    echo "CONN_STRING=mongodb://127.0.0.1:$EXPOSED_PORT/?directConnection=true" > $workdir/src/.evergreen/.local_atlas_uri
}

fetch_local_atlas_uri() {
    # shellcheck disable=SC2154
    . $workdir/src/.evergreen/.local_atlas_uri

    export CONN_STRING=$CONN_STRING
    echo "$CONN_STRING"
}

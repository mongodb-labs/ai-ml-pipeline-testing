#!/bin/bash

set -eu

# Get the MONGODB_URI.
SCRIPT_DIR=$(realpath "$(dirname ${BASH_SOURCE[0]})")
ROOT_DIR=$(dirname $SCRIPT_DIR)
. $ROOT_DIR/env.sh

. $ROOT_DIR/.evergreen/utils.sh

PYTHON_BINARY=$(find_python3)

# Return the URI with the database path replaced by the given name.
set_database() {
    local uri="$1"
    local database="$2"
    local base="$uri"
    local query=""
    if [[ "$uri" == *"?"* ]]; then
        base="${uri%%\?*}"
        query="?${uri#*\?}"
    fi
    local scheme="${base%%://*}"
    local host_and_path="${base#*://}"
    local host="${host_and_path%%/*}"
    printf '%s://%s/%s%s' "$scheme" "$host" "$database" "$query"
}

# mlflow-mongodb requires Python 3.11 or newer. Let uv install a suitable
# interpreter when the host toolchain is older.
$PYTHON_BINARY -m venv venv_pipeline
source venv_pipeline/bin/activate

pip install uv certifi

SSL_CERT_FILE=$(python -c "import certifi; print(certifi.where())")
export SSL_CERT_FILE

uv venv --python 3.11 venv_tests
source venv_tests/bin/activate

uv pip install -e ".[dev]"

# The MLflow MongoDB store requires a database name in the URI.
MONGODB_URI=$(set_database "$MONGODB_URI" "$DATABASE")
export MONGODB_URI

python -m pytest tests/unit tests/functional

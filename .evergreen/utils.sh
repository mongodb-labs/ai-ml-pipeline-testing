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
    elif [ "Windows_NT" = "$OS" ]; then # Magic variable in cygwin
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

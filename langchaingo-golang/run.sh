#!/bin/bash

set -eu

GO_VERSION="go1.22"

cd vectorstores/mongovector

export PATH="$PATH:/opt/golang/$GO_VERSION/bin"
export GOROOT="/opt/golang/$GO_VERSION"

go test -v -failfast -race -shuffle=on

#!/bin/bash

set -eu

GO_VERSION="go1.22"

cd vectorstores/mongovector

export PATH="$PATH:/opt/golang/$GO_VERSION/bin"
export GOROOT="/opt/golang/$GO_VERSION"

# TODO(GODRIVER-3606): Update expected error in LangChainGo test for
# non-tokenized filter
go test -v -failfast -race -shuffle=on \
  -skip "TestStore_SimilaritySearch_NonExactQuery/with_non-tokenized_filter"

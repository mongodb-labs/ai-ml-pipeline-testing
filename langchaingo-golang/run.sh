#!/bin/bash

set -eu

cd langchaingo-repo/vectorstores/mongovector

go test -v -failfast

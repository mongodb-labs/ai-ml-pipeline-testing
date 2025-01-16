#!/bin/bash

set -eu

cd langchaingo/vectorstores/mongovector

go test -v -failfast

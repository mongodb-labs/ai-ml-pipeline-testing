# See https://just.systems/man/en/ for instructions
set shell := ["bash", "-c"]
set dotenv-filename := "env.sh"

# Make the default recipe private so it doesn't show up in the list.
[private]
default:
  @just --list

_base dir:
    DIR={{dir}} bash .evergreen/fetch-secrets.sh
    DIR={{dir}} bash .evergreen/fetch-repo.sh

setup dir:
    just _base {{dir}}
    DIR={{dir}} bash .evergreen/provision-atlas.sh

setup-remote dir:
    just _base {{dir}}
    DIR={{dir}} bash .evergreen/setup-remote.sh

test *args="":
    MAX_ATTEMPTS=1 bash .evergreen/execute-tests.sh {{args}}

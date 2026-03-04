# Testing Pipeline For Third-Party AI/ML MongoDB Integrations

## What is it?

This repository exists to test our integrations in Third-Party AI/ML libraries.

See the [DBX AI/ML Integrations Contribution Guide](https://wiki.corp.mongodb.com/spaces/DRIVERS/pages/260909214/DBX+AI+ML+Integrations+Contribution+Guide) for background information and motivation.

## How to add a test

<<<<<<< aclark4life-patch-1
> **NOTE** All tests run against this repo are now required to work against a local Atlas deployment. See details below to ensure proper setup.

### Test Layout

Each AI/ML pipeline is sorted by the composite of the name of the library, and the driver language the library is implemented in. This comes out in the format `{pipeline}-{language}` --> `semantic-kernel-python`. All tests should be scoped within the bounds of these subdirectories.

Each subdirectory is scoped to run only one AI/ML integration's suite of tests for one language within that cloned repository. For example, if an AI/ML integration has both a Python and C# implementation of Atlas Vector Search, two subdirectories need to be made: one for Python, titled `{repo}-python`, and one for C#, titled `{repo}-csharp`. See `semantic-kernel-*` subdirectories in the layout example below.

Within each subdirectory you should expect to have:

- `run.sh` -- A script that should handle any additional library installations and steps for executing the test suite. This script should not populate the Atlas database with any required test data.
- `config.env` - A file that defines the following environment variables:
  - `REPO_NAME` -- The name of the AI/ML framework repository that will get cloned
  - `REPO_ORG` -- The Github org of the repository
  - `REPO_BRANCH` -- The optional branch to clone
  - `DATABASE` -- The optional database where the Atlas CLI will load your index configs
- `database/` -- An optional directory used by `.evergreen/scaffold_atlas.py` to populate a MongoDB database with test data. Only provide this if your tests require pre-populated data.
- `database/{collection}.json` -- An optional JSON file containing one or more MongoDB documents that will be uploaded to `$DATABASE.{collection}` in the local Atlas instance. Only provide this if your tests require pre-populated data.
- `indexConfig.json` -- An optional file containing configuration for a specified Atlas Search Index.
- Additionally, you can add other useful files, including `.env` files, if required by your tests.

The general layout of this repo looks like this:

```bash
├── LICENSE                                     # License Agreement
├── README.md                                   # This Document
├── langchain-python                            # Folder scoped for one Integration
│   └── run.sh                                  # Script that executes test
├── semantic-kernel-csharp                      # Folder scoped for one Integration
│   ├── database                                # Optional database definition directory
│   │   └── nearestSearch.json                  # Populates $DATABASE.nearestSearch
│   │   └── furthestSearch.json                 # Populates $DATABASE.furthestSearch
│   ├── indexes                                 # Optional Index definitions directory
│   │   └── indexConfig.json                    # Optional Search index definition
|   ├── config.env                              # Configuration file
│   └── run.sh                                  # Script that executes test
|
├── semantic-kernel-python                      # Folder scoped for one Integration
│   ├── database                                # Optional database definition
│   │   └── nearestSearch.json                  # Populates $DATABASE.nearestSearch
│   │   └── furthestSearch.json                 # Populates $DATABASE.furthestSearch
│   ├── indexConfig.json                        # Creates Search Index on $DATABASE
|   ├── config.env                              # Configuration file
│   └── run.sh                                  # Script that executes test
```

### Configuring an Atlas CLI for testing

Each test subdirectory will automatically have its own local Atlas deployment. As a result, database and collection names will not conflict between different AI/ML integrations. To connect to your local Atlas using a connection string, `utils.sh` has a `fetch_local_atlas_uri` that you can call from the `run.sh` script within your subdirectory. For example:

```bash
. .evergreen/utils.sh

CONN_STRING=$(fetch_local_atlas_uri)
```

Stores the local Atlas URI within the `CONN_STRING` var. The script can then pass `CONN_STRING` as an environment variable to the test suite.

#### Running tests locally.

We can run the tests with a local checkout of the repo.

For example, to run the `docarray` tests using local atlas:
=======
See the [Contributing Guide](./CONTRIBUTING.md#how-to-add-a-test)
>>>>>>> main

## Upstream Repo Considerations

See the [Contributing Guide](./CONTRIBUTING.md#upstream-repo-considerations)

## Local testing

See the [Contributing Guide](./CONTRIBUTING.md#running-tests-locally)

## Running a patch build of a given PR

Rather than making a new branch and modifying a `config.env` file, you can run a patch build as follows:

```bash
evergreen patch -p ai-ml-pipeline-testing --param REPO_ORG="<my-org>" --param REPO_BRANCH="<my-branch>" -y -d "<my-message>"
```

For example:

```bash
evergreen patch -p ai-ml-pipeline-testing --param REPO_ORG=caseyclements --param REPO_NAME="langchain-mongodb" --param REPO_BRANCH="INTPYTHON-629" -y -d "Increased retries to 4."
```

## Handling Failing Tests

Tests are run periodically (nightly). All failing test suites are automatically retried up to two times. Any failures will propagate into both the `dbx-ai-ml-testing-pipline-notifications` and `dbx-ai-ml-testing-pipeline-notifications-{language}` channel. Repo owners of this `ai-ml-testing-pipeline` library are required to join the `dbx-ai-ml-testing-pipeline-notifications`. Pipeline specific implementers must **at least** join `dbx-ai-ml-testing-pipline-notifications-{language}` (e.g. whomever implemented `langchain-js` must at least be a member of `dbx-ai-ml-testing-pipeline-notifications-js`).

If tests are found to be failing, and cannot be addressed quickly, the responsible team MUST create a JIRA ticket within their team's project (e.g. a python failure should generate an `INTPYTHON` ticket), and disable the relevant tests
in the `config.yml` file, with a comment about the JIRA ticket that will address it.

This policy will help ensure that a single failing integration does not cause noise in the `dbx-ai-ml-testing-pipeline-notifications` or `dbx-ai-ml-testing-pipeline-notifications-{language}` that would mask other
failures.

# Testing Pipeline For Third-Party AI/ML MongoDB Integrations

## What is it?

This repository exists to test our integrations in Third-Party AI/ML libraries.

## Motivation

With the public release of `$vectorSearch`, we have needed to integrate into these AI/ML sponsored libraries.
([LangChain](https://github.com/langchain-ai/langchainjs), [LlamaIndex](https://github.com/run-llama/llama_index), [Semantic Kernel](https://github.com/microsoft/semantic-kernel)... etc) This repository runs continuous testing against each of these repos.

## How to add a test

> **NOTE** All tests run against this repo are now required to work against a local Atlas deployment. See details below to ensure proper setup.

### Test Layout

Each AI/ML pipeline is sorted by the composite of the name of the library, and the driver language the library is implemented in. This comes out in the format `{pipeline}-{language}` --> `semantic-kernel-python`. All tests should be scoped within the bounds of these subdirectories.

Each subdirectory is scoped to run only one AI/ML integration's suite of tests for one language within that cloned repository. For example, if an AI/ML integration has both a Python and C# implementation of Atlas Vector Search, two subdirectories need to be made: one for Python, titled `{repo}-python`, and one for C#, titled `{repo}-csharp`. See `semantic-kernel-*` subdirectories in the layout example below.

Within each subdirectory you should expect to have:

- `run.sh` -- A script that should handle any additional library installations and steps for executing the test suite. This script should not populate the Atlas database with any required test data.
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
│   └── run.sh                                  # Script that executes test
├── semantic-kernel-python                      # Folder scoped for one Integration
│   ├── database                                # Optional database definition
│   │   └── nearestSearch.json                  # Populates $DATABASE.nearestSearch
│   │   └── furthestSearch.json                 # Populates $DATABASE.furthestSearch
│   ├── indexConfig.json                        # Creates Search Index on $DATABASE
│   └── run.sh                                  # Script that executes test
```

### Configuring a Atlas CLI for testing

Each test subdirectory will automatically have its own local Atlas deployment. As a result, database and collection names will not conflict between different AI/ML integrations. To connect to your local Atlas using a connection string, `utils.sh` has a `fetch_local_atlas_uri` that you can call from the `run.sh` script within your subdirectory. For example:

```bash
. .evergreen/utils.sh

CONN_STRING=$(fetch_local_atlas_uri)
```

Stores the local Atlas URI within the `CONN_STRING` var. The script can then pass `CONN_STRING` as an environment variable to the test suite.

#### Running tests locally.

We can run the tests with a local checkout of the repo.

For example, to run the `docarray` tests using local atlas:

```bash
export DIR=docarray
bash .evergreen/fetch-repo.sh
bash .evergreen/provision-atlas.sh
bash .evergreen/execute-tests.sh
```

Use `.evergreen/setup-remote.sh` instead of `.evergreen/provision-atlas.sh` to test against the remote cluster.

#### Pre-populating the Local Atlas Deployment

You can pre-populate a test's local Atlas deployment before running the `run.sh` script by providing JSON files in the optional `database` directory of the created subdirectory. The `.evergreen/scaffold_atlas.py` file will search for every JSON file within this database directory and upload the documents to the database provided by the `DATABASE` expansion provided in the build variant of the `.evergreen/config.yml` setup. The collection the script uploads to is based on the name of your JSON file:

- `critical_search.json` with `DATABASE: app` will upload all of its contents to `app.critical_search` collection.

To create a search index, provide the search index configuration in the `indexes` dir; the file needs to be a json and for each individual index you wish to create, you must make a separate json file; for easier readability, please name each index configuration after the collection the index will be defined on or the name of the index itself. If multiple indexes will define one collection or multiples collections within a database share the name index name, append a name "purpose" (test_collection_vectorsearch_index) to favor readability. The evergreen script will then create the search index before the `run.sh` script is executed. See the ["Create an Atlas Search Index and Run a Query"](https://www.mongodb.com/docs/atlas/cli/stable/atlas-cli-deploy-fts/#create-an-atlas-search-index-and-run-a-query) documentation instructions on how to create a search index using Atlas CLI.

If you need more customized behavior when populating your database or configuring your local Atlas deployment, include that behavior in your `run.sh` script.

### Unpacking the Evergreen config file

Test execution flow is defined in `.evergreen/config.yml`. The test pipeline's config is structured as follows:

**[Build variants](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files#build-variants)** -- This is the highest granularity we will use to define how and when a test pipeline will run. A build variant should only ever be scoped to service one test pipeline. There can be multiple tasks run within a build variant, but they should all only scope themselves to a singular test pipeline in order to maintain an ease of traceability for testing.

- `name` -- This should be in the format `test-{pipeline}-{language}-{os}`
- `display_name` -- This can be named however you see fit. Ensure it is easy to understand. See `.evergreen/config.yml` for examples
- [`expansions`](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files/#expansions) -- Build variant specific variables. Expansions that need to be maintained as secrets should be stored in [the Evergreen project settings](https://spruce.mongodb.com/project/ai-ml-pipeline-testing/settings/variables) using [variables](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-and-Distro-Settings#variables). Some common expansions needed are:

  - `DIR` -- The subdirectory where the tasks will run
  - `REPO_NAME` -- The name of the AI/ML framework repository that will get cloned
  - `CLONE_URL` -- The Github URL to clone into the specified `DIR`
  - `DATABASE` -- The optional database where the Atlas CLI will load your index configs

- `run_on` -- Specified platform to run on. `rhel87-small` should be used by default. Any other distro may fail Atlas CLI setup.
- `tasks` -- Tasks to run. See below for more details
- `cron` -- The tests are run via a cron job on a nightly cadence. This can be modified by setting a different cadence. Cron jobs can be scheduled using [cron syntax](https://crontab.guru/#0_0_*_*_*)

**[Tasks](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files#tasks)** -- These are the "building blocks" of our runs. Here is where we consolidate the specific set of functions. The basic parameters to add are shown below

- `name` -- This should be in the format `test-{pipeline}-{language}`
- `commands` -- See below.

**[Functions](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files#functions)** -- We've defined some common functions that will be used. See the `.evergreen/config.yml` for example cases. The standard procedure is to fetch the repository, provision Atlas as needed, and then execute the tests specified in the `run.sh` script you create. Ensure that the expansions are provided for these functions, otherwise the tests will run improperly and most likely fail.

-   [`fetch repo`](https://github.com/mongodb-labs/ai-ml-pipeline-testing/blob/main/.evergreen/config.yml#L30) -- Clones the library's git repository; make sure to provide the expansion CLONE_URL
-   [`execute tests`](https://github.com/mongodb-labs/ai-ml-pipeline-testing/blob/main/.evergreen/config.yml#L51) -- Uses [subprocess.exec](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Commands#subprocessexec) to run the provided `run.sh` file. `run.sh` must be within the specified `DIR` path.
-   `fetch source` -- Retrieves the current (`ai-ml-pipeline-testing`) repo
-   `setup atlas cli` -- Sets up the local Atlas deployment

## Upstream Repo Considerations

For better or worse, we do not maintain AI/ML libraries with which we integrate.
We provide workarounds for a few common issues that we encounter.

### Third-Party AI/ML library Maintainers have not merged our changes

As we develop a testing infrastructure, we commonly make changes to our integrations with the third-party library.
This is the case, in particular, when we add a new integration.
Over time, we may make bug fixes, add new features, and update the API.
At the start, we will hopefully add the integration tests themselves.

The bad news is that the maintainers of the AI/ML packages may take considerable
time to review and merge our changes. The good news is that we can begin testing
without pointing to the main branch of the upstream repo.
The parameter value of the `CLONE_URL` is very flexible.
We literally just call `git clone $CLONE_URL`.
As such, we can point to an arbitrary branch on an arbitrary repo.
While developing, we encourage developers to point to a feature branch
on their own fork, and add a TODO with the JIRA ticket to update the url
once the pull-request has been merged.

### Patching upstream repos

We provide a simple mechanism to make changes to the third-party packages
without requiring a pull-request (and acceptance by the upstream maintainers).
This is done via Git Patch files.

Patch files are created very simply: `git diff > mypatch.patch`.
If you can believe it, this was the primary mechanism to share code with another maintainer
before pull-requests existed!
To apply patches, add them to a `patches` directory within the `$DIR` of your build variant.
As of this writing, the `chatgpt-retrieval-plugin` contains an example that you may use as a reference.
You can create a number of different patch files, which will be applied recursively.
This is useful to describe rationale, or to separate out ones that will be removed
upon a merged pull-request to the upstream repo.

During ChatGPT Retrieval Plugin integration, we ran into build issues on Evergreen hosts.
In this case, the package failed to build from source.
It required a library that wasn't available on the host and had no wheel on PyPI.
As it turned out, the package was actually an optional requirement,
and so a one-line change to `pyproject.toml` solved our problem.

We realized that we could easily get this working without changing the upstream
simply by applying a git patch file.
This is a standard practice used by `conda package` maintainers,
as they often have to build for a more broad set of scenarios than the original authors intended.

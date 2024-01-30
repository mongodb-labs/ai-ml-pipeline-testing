# Testing Pipeline For Third-Party AI/ML MongoDB Integrations

## What is it?

This repository exists to test our integrations in Third-Party AI/ML testing libraries.

## Motivation

With the public release of `$vectorSearch`, we have needed to integrate into these AI/ML sponsored libraries. 
([LangChain](https://github.com/langchain-ai/langchainjs), [LlamaIndex](https://github.com/run-llama/llama_index), [Semantic Kernel](https://github.com/microsoft/semantic-kernel)... etc) This repository runs continuous testing against each of these repos.

## How to add a test
> **NOTE** All tests run against this repo are now required to work against a local atlas deployment. See details below to ensure proper set-up

### Test Layout

Each AI/ML pipeline is sorted by the composite of the name of the library, and the driver language the library is implemented in. This comes out in the format `{pipeline}-{language}` --> `semantic-kernel-python`. All tests should be scoped within the bounds of these subdirectories.

Within each subdirectory you should expect to have:
- `run.sh`  --  A script that should handle any additional library installations and steps for executing the test suite. This script should not populate the Atlas database with any required test data.
- `database/` -- An optional directory used by `.evergreen/scaffold_atlas.py` to populate a MongoDB database with test data. Only provide this if your tests require pre-populated data.
- `database/{collection}.json` -- An optional JSON file containing one or more MongoDB documents that will be uploaded to `$DATABASE.{collection}` in the local Atlas instance. Only provide this if your tests require pre-populated data.
- `indexConfig.json` -- An optional file containing configuration for a specified Atlas Search Index.
- Additionally, you can add other useful files, including `.env` files, if required by your tests.

Each subdirectory holds the space for one repository, and within each subdirectory is where evergreen will clone the specified third-party library.

The general layout of this repo will looks like this:
```bash
├── LICENSE										# License Agreeement
├── README.md									# This Document
├── langchain-python							# Folder scoped for one Integration
│   └── run.sh									# script that executes test
├── semantic-kernel-csharp						# Folder scoped for one Integration
│   ├── database								# Optional database definition
│   │   └── nearestSearch.json					# Populates $DATABASE.nearestSearch
│   │   └── furthestSearch.json					# Populates $DATABASE.furthestSearch
│   ├── indexConfig.json						# Creates Search Index on $DATABASE
│   └── run.sh									# script that executes test
```

### Configuring a Atlas CLI for testing
Each test subdirectory will automatically have its own local Atlas deployment. As a result, database and collection names will not conflict between different AI/ML integrations. To connect to your local Atlas using a connection string, call `$atlas` from the `run.sh` script within your subdirectory. This exposes the Atlas CLI binary. For example:

```bash
CONN_STRING=$($atlas deployments connect $DIR --connectWith connectionString)
```
Stores the local Atlas URI within the `CONN_STRING` var. It can then pass `CONN_STRING` as an environment variable to the test suite.

#### Pre-populating the Local Atlas Deployment
You can pre-populate a test's local Atlas deployment before running the `run.sh` script by providing JSON files in the optional `database` directory of the created subdirectory. The `.evergreen/scaffold_atlas.py` file will search for every JSON file within this database directory and upload the documents to the database provided by the `DATABASE` expansion provided in the buildvariant of the `.evergreen/config.yml` setup. The collection the script uploads to is based on the name of your JSON file:
- `critical_search.json` with `DATABASE: app` will upload all of its contents to `app.critical_search` collection.

To create a search index, provide the search index configuration in the `indexConfig.json` file. The evergreen script will then create the search index before the `run.sh` script is executed. Adding multiple search indexes in the setup stage is not supported, but more indexes can be included in the `run.sh` by using the referenced `$atlas` binary.

If you need more customized behavior when populating your database or configuring your local Atlas deployment, include that behavior in your `run.sh` script. The path to the `$atlas` binary is provided to that script. You can view more ways to configure local Atlas by visiting the [Atlas CLI local deployments documentation](https://www.mongodb.com/docs/atlas/cli/stable/atlas-cli-local-cloud/).

### Unpacking the Evergreen config file

Test execution flow is defined in `.evergreen/config.yml`. The test pipeline's config is structured as follows:

**[Buildvariants](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files#build-variants)** -- This is the highest granularity we will use to define how and when a test pipeline will run. A build variant defined should only ever be scoped to service one test pipeline. There can be multiple tasks run within the specified build variant, but they should all only scope themselves to a singular test pipeline in order to maintain an ease of traceability for testing.

-   `name` -- This should be in the format `test-{pipeline}-{language}-{os}`
-   `display_name` -- This can be named however you see fit. Ensure it is easy to understand. See `.evergreen/config.yml` for examples
-   [`expansions`](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files/#expansions) -- Build variant specific variables. Expansions that need to be maintained as secrets should be stored in [the Evergreen project settings](https://spruce.mongodb.com/project/ai-ml-pipeline-testing/settings/variables) using [variables](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-and-Distro-Settings#variables). Some common expansions needed are:
    -   `DIR` -- The subdirectory where the tasks will run
    -   `REPO_NAME` -- The name of the AI/ML framework repository that will get cloned
    -   `CLONE_URL` -- The Github URL to clone into the specified `DIR`
    -   `DATABASE` -- The optional database where the Atlas CLI will load your index configs 

-   `run_on` -- Specified platform to run on. `rhel87-small` is a fine default. Any other distro may fail atlas cli setup.
-   `tasks` -- Tasks to run. See below for more details
-   `cron` -- The tests are run via a cron job on a nightly cadence. This can be modified by setting a different cadence. Cron jobs can be scheduled using [cron syntax](https://crontab.guru/#0_0_*_*_*)

**[Tasks](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files#tasks)** -- These are the "building blocks" of our runs. Here is where we consolidate the specific set of functions. The basic parameters to add are shown below

-   `name` -- This should be in the format `test-{pipeline}-{language}`
-   `commands` -- See below.

**[Functions](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files#functions)** -- We've defined some common functions that will be used. See the `.evergreen/config.yml` for example cases. The standard procedure is to fetch the repository, provision atlas however needed, and then execute the tests specified in the `run.sh` script you create. Ensure that the expansions are provided for these functions, otherwise the tests will run improperly and most likely fail.

-   [`fetch repo`](https://github.com/mongodb-labs/ai-ml-pipeline-testing/blob/main/.evergreen/config.yml#L30) -- Clones the library's git repository; make sure to provide the expansion CLONE_URL
-   [`execute tests`](https://github.com/mongodb-labs/ai-ml-pipeline-testing/blob/main/.evergreen/config.yml#L51) -- Uses [subprocess.exec](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Commands#subprocessexec) to run the provided `run.sh` file. `run.sh` must be within the specified `DIR` path.
-   `fetch source` -- Retrieves the current (`ai-ml-pipeline-testing`) repo
-   `setup atlas cli` -- Sets up the local Atlas deployment

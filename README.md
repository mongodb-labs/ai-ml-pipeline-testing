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
- `run.sh`  --  This run script will handle any additional library installation, or steps to get the test suite running. Note, it does not need to include steps to scaffold the atlas database.
- `database/` -- Optional directory where the `.evergreen/scaffold_atlas.py` will read and use to population a mongo database with collection information. Only provide this if your tests assume a pre-populated database
- `database/{collection}.json` -- JSON file with the mongo documents that will be upload to `$DATABASE.{collection}`
- `indexConfig.json` -- File with Atlas Search Index configuration.
- Additionally, you can add useful environment files such as a `.env` file.

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
Each test subdirectory will automatically have its own local atlas deployment. Ergo, there is no need to worry about conflicting database names amongst AI/ML pipeline integrations. To retrieve the connection string to connect to local atlas, you can call `$atlas` from your `run.sh` script within your subdirectory. This exposes the atlas binary. For example:

```bash
CONN_STRING=$($atlas deployments connect $DIR --connectWith connectionString)
```
Stores the local atlas mongodb uri within the CONN_STRING var. It can then place that as an `ENV_VAR` prior to running the test suite for the integrated library.

#### Pre-populating the Local Atlas Deployment
You can pre-populate the generated local atlas deployment before running the `run.sh` script by providing json files in the `database` directory of your created subdirectory. The `.evergreen/scaffold_atlas.py` file will search for every json file within this database directory and upload the documents to the database provided by the `DATABASE` expansion provided in your `config.yml` setup. The collection the script uploads to will be based on the name of your json file:
- `critical_search.json` with `DATABASE: app` will upload all of its contents to `app.critical_search` collection.

To create a search index, please provide the search index configuration in the `indexConfig.json` file. The evergreen script will create the search index on your behalf before the `run.sh` script is run so long as this file is found.

If you need more control on populating your database or configuring your local atlas deployment further, please have that run within the `run.sh` script. The path to the `$atlas` binary is provided within that script and you can view more ways to configure local atlas by visiting the [atlas cli local deployments documentation](https://www.mongodb.com/docs/atlas/cli/stable/atlas-cli-local-cloud/).

### Unpacking the Evergreen

The governing flow for how tests are executed stem from the `.evergreen/config.yml` where the evergreen script runs each test. The way we've structured the evergreen layout has this flow.

**[Buildvariants](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files#build-variants)** -- This is the highest granularity we will use to define how and when a test pipeline will run. A build variant defined should only ever be scoped to service one test pipeline. There can be multiple tasks run within the specified build variant, but they should all only scope themselves to a singular test pipeline in order to maintain an ease of traceability for testing.

-   `name` -- This should be in the format test-{pipeline}-{language}-{os}
-   `display_name` -- This can be named however you see fit. Ensure it is easy to understand. See `.evergreen/config.yml` for examples
-   [`expansions`](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files/#expansions) -- These are how we store buildvariant specific variables. Additionally, for expansions that need to be maintained as secrets, please update those in [the evergreen project settings](https://spruce.mongodb.com/project/ai-ml-pipeline-testing/settings/variables) using [variables](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-and-Distro-Settings#variables). Some common expansions needed are:
    -   `DIR` -- The subdirectory where the tasks will run
    -   `REPO_NAME` -- The name of the repository that will get cloned
    -   `CLONE_URL` -- The github url to clone into the specified DIR
    -   `DATABASE` -- The database atlas cli will load your index configs (optional)

-   `run_on` -- Specified platform to run on. `rhel90-small` is a fine default. Any other distro may fail atlas cli setup.
-   `tasks` -- Tasks to run. See below for more details
-   `cron` -- The tests are run via a cron job on a weekly cadence. However, this can be augmented by setting a different cadence. Cron jobs can be scheduled using [cron syntax](https://crontab.guru/#0_0_*_*_0)

**[Tasks](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files#tasks)** -- These are the "building blocks" of our runs. Here is where we consolidate the specific set of functions. The basic parameters to add are shown below

-   `name` -- This should be in the format `test-{pipeline}-{language}`
-   `commands` -- See below.

**[Functions](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files#functions)** -- We've defined some common functions that will be used. See the `.evergreen/config.yml` for example cases. The standard procedure is to fetch the repository, provision atlas however needed, and then execute the tests specified in the `run.sh` script you create. Ensure that the expansions are provided for these functions, otherwise the tests will run improperly and most likely fail.

-   [`fetch repo`](https://github.com/mongodb-labs/ai-ml-pipeline-testing/blob/main/.evergreen/config.yml#L30) -- Clone's the library's git repository; make sure to provide the expansion CLONE_URL
-   [`execute tests`](https://github.com/mongodb-labs/ai-ml-pipeline-testing/blob/main/.evergreen/config.yml#L51) -- Using [subprocess.exec](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Commands#subprocessexec) Runs the provided `run.sh` file that needs to be within the specified DIR path.
-   `fetch source` -- Retrieves the current (`ai-ml-pipeline-testing`) repo
-   `setup atlas cli` -- Sets up the local atlas deployment

# Testing Pipeline For Third-Party AI/ML MongoDB Integrations

## What is it?

This repository exists to test our integrations in Third-Party AI/ML testing libraries.

## Motivation

With the public release`$vectorSearch`, we have needed to integrate into these AI/ML sponsored libraries. 
([LangChain](https://github.com/langchain-ai/langchainjs), [LlamaIndex](https://github.com/run-llama/llama_index), [Semantic Kernel](https://github.com/microsoft/semantic-kernel)... etc) This repository runs continuous testing against each of these repos.

## How to add a test

### Test Layout

Each AI/ML pipeline is sorted by the composite of the name of the library, and the driver language the library is implemented in. This comes out in the format `{pipeline}-{language}` --> `semantic-kernel-python`. All tests should be scoped within the bounds of these subdirectories.

Within each subdirectory you should expect to have a `run.sh` file. This run script will handle any additional installation, or scaffolding steps to get the test suite running. Note, it does not need to include steps to scaffold the atlas database. Additionally, you can add useful environment files such as a `.env` file or atlas vector search index configurations.

Each subdirectory holds the space for one repository, and within each subdirectory is where evergreen will clone the specified third-party library.

### Unpacking the Evergreen

The governing flow for how tests are executed stem from the `.evergreen/config.yml` where the evergreen script runs each test. The way we've structured the evergreen layout has this flow.

**[Buildvariants](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files#build-variants)** -- This is the highest granularity we will use to define how and when a test pipeline will run. A build variant defined should only ever be scoped to service one test pipeline. There can be multiple tasks run within the specified build variant, but they should all only scope themselves to a singular test pipeline in order to maintain an ease of traceability for testing.

-   `name` -- This should be in the format test-{pipeline}-{language}-{os}
-   `display_name` -- This can be named however you see fit. Ensure it is easy to understand. See `.evergreen/config.yml` for examples
-   [`expansions`](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files/#expansions) -- These are how we store buildvariant specific variables. Additionally, for expansions that need to be maintained as secrets, please update those in t[he evergreen project settings](https://spruce.mongodb.com/project/ai-ml-pipeline-testing/settings/variables) using [variables](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-and-Distro-Settings#variables). Some common expansions this takes are:
    -   `DIR` -- The subdirectory where the tasks will run
    -   `REPO_NAME` -- The name of the repository that will get cloned
    -   `CLONE_URL` -- The github url to clone into the specified DIR

-   `run_on` -- Specified platform to run on. `ubuntu2204-small` is a fine default
-   `tasks` -- Tasks to run. See below for more details
-   `cron` -- The tests are run via a cron job on a weekly cadence. However, this can be augmented by setting a different cadence. Cron jobs can be scheduled using [cron syntax](https://crontab.guru/#0_0_*_*_0)

**[Tasks](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files#tasks)** -- These are the "building blocks" of our runs. Here is where we consolidate the specific set of functions. The basic parameters to add are shown below

-   `name` -- This should be in the format `test-{pipeline}-{language}`
-   `commands` -- See below.

**[Functions](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Configuration-Files#functions)** -- We've defined some common functions that will be used. See the `.evergreen/config.yml` for example cases. The standard procedure is to fetch the repository, provision atlas however needed, and then execute the tests specified in the `run.sh` script you create. Ensure that the expansions are provided for these functions, otherwise the tests will run improperly and most likely fail.

-   [`fetch repo`](https://github.com/mongodb-labs/ai-ml-pipeline-testing/blob/main/.evergreen/config.yml#L30) -- Clone's the library's git repository; make sure to provide the expansion CLONE_URL
-   [`execute tests`](https://github.com/mongodb-labs/ai-ml-pipeline-testing/blob/main/.evergreen/config.yml#L51) -- Using [subprocess.exec](https://docs.devprod.prod.corp.mongodb.com/evergreen/Project-Configuration/Project-Commands#subprocessexec) Runs the provided `run.sh` file that needs to be within the specified DIR path.


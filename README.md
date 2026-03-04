# Testing Pipeline For Third-Party AI/ML MongoDB Integrations

## What is it?

This repository exists to test our integrations in Third-Party AI/ML libraries.

See the [DBX AI/ML Integrations Contribution Guide](https://wiki.corp.mongodb.com/spaces/DRIVERS/pages/260909214/DBX+AI+ML+Integrations+Contribution+Guide) for background information and motivation.

## How to add a test

See the [Contributing Guide](./CONTRIBUTING.md#how-to-add-a-test)

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

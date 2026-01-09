# Run MongoDB Community Search

Script run MongoDB Community Search Locally using docker compose.

## Prerequisite

1. Follow through the steps outlined
   [here](https://github.com/10gen/mongot/blob/master/docs/development/docker.md#authenticate-with-ecr)
   to authenticate with ECR. We depend on an internally released image of mongot
   available on an internal registry.
2. Ensure the following entries are in your `/etc/hosts` file: `127.0.0.1 host.docker.internal`

## Setup

Set required environment variables:

```bash
export VOYAGE_QUERY_API_KEY=<your-query-api-key>
export VOYAGE_INDEXING_API_KEY=<your-indexing-api-key>
```

## Run

```bash
sh ./start-services.sh
```

This will:

- Create secret files from environment variables (if not present)
- Start MongoDB and mongot containers

Note: If you already have the secrets folder in your repo. The script will skip generating those secrets again and also skip the permission modifications. The permissions for the files containing secrets should be readonly otherwise `mongot` will refuse configuring a provider. Ensure that your files containing api keys that mounted to `mongot` container in the `docker-compose.yml` have the following permissions: `400`.

## Ports

- MongoDB: 27017
- Mongot Query: 27028
- Mongot Metrics: 9946
- Mongot Health: 8080

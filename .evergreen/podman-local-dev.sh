#!/bin/bash
# start mongodb-atlas-local container, because of a bug in podman we have to define the healtcheck ourselves (is the same as in the image)

echo "Starting the container"
CONTAINER_ID=$(podman run --rm -d -e DO_NOT_TRACK=1 -P --health-cmd "/usr/local/bin/runner healthcheck" mongodb/mongodb-atlas-local:latest)

echo "waiting for container to become healthy..."
function wait() {
  CONTAINER_ID=$1
  echo "waiting for container to become healthy..."
  podman healthcheck run "$CONTAINER_ID"
  for _ in $(seq 600); do
      STATE=$(podman inspect -f '{{ .State.Health.Status }}' "$CONTAINER_ID")

      case $STATE in
        healthy)
          echo "container is healthy"
          return 0
          ;;
        unhealthy)
          echo "container is unhealthy"
          podman logs "$CONTAINER_ID"
          stop
          exit 1
          ;;
        *)
          echo "Unrecognized state $STATE"
        sleep 1
      esac      
  done

  echo "container did not get healthy within 120 seconds, quitting"
  podman logs mongodb_atlas_local
  stop
  exit 2
}

wait "$CONTAINER_ID"
EXPOSED_PORT=$(podman inspect --format='{{ (index (index .NetworkSettings.Ports "27017/tcp") 0).HostPort }}' "$CONTAINER_ID")

export CONN_STRING="mongodb://127.0.0.1:$EXPOSED_PORT/?directConnection=true"

echo "CONN_STRING=mongodb://127.0.0.1:$EXPOSED_PORT/?directConnection=true" > .local_atlas_uri
echo "ATLAS_LOCAL_URL set to $CONN_STRING"
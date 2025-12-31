set -eu
pushd $(dirname ${BASH_SOURCE:-$0}) > /dev/null

source ../../secrets-export.sh
export VOYAGE_QUERY_API_KEY=$VOYAGEAI_API_KEY
export VOYAGE_INDEXING_API_KEY=$VOYAGEAI_API_KEY

grep -qxF '127.0.0.1 host.docker.internal' /etc/hosts || echo '127.0.0.1 host.docker.internal' | sudo tee -a /etc/hosts 

chmod 400 mongot.pwd

# Create secrets directory if it doesn't exist
mkdir -p secrets

if [ ! -f secrets/voyage-api-query-key ]; then
  if [ -z "$VOYAGE_QUERY_API_KEY" ]; then
    echo "Error: VOYAGE_QUERY_API_KEY environment variable is not set."
    echo "Please set it using: export VOYAGE_QUERY_API_KEY=<your-api-key>"
    exit 1
  fi
fi

if [ ! -f secrets/voyage-api-indexing-key ]; then
  if [ -z "$VOYAGE_INDEXING_API_KEY" ]; then
    echo "Error: VOYAGE_INDEXING_API_KEY environment variable is not set."
    echo "Please set it using: export VOYAGE_INDEXING_API_KEY=<your-api-key>"
    exit 1
  fi
fi

# Create voyage api key files from environment variables
if [ ! -f secrets/voyage-api-query-key ]; then
  printf '%s' "$VOYAGE_QUERY_API_KEY" > secrets/voyage-api-query-key
  chmod 400 secrets/voyage-api-query-key
  echo "Created secrets/voyage-api-query-key"
else
  echo "secrets/voyage-api-query-key already exists, skipping."
fi

if [ ! -f secrets/voyage-api-indexing-key ]; then
  printf '%s' "$VOYAGE_INDEXING_API_KEY" > secrets/voyage-api-indexing-key
  chmod 400 secrets/voyage-api-indexing-key
  echo "Created secrets/voyage-api-indexing-key"
else
  echo "secrets/voyage-api-indexing-key already exists, skipping."
fi

docker network create search-community; true
docker compose down; true
docker compose up -d

# Wait for the healthcheck
URL="http://127.0.0.1:8080/healthcheck"  

echo "Waiting for the server to be alive and respond with the expected status..."  
set +e
while true; do  
  # Make the request and capture response with detailed debugging  
  RESPONSE=$(curl --max-time 10 -s "$URL")  
  CURL_EXIT_CODE=$?  
  
  # Check for Curl exit code
  if [ "$CURL_EXIT_CODE" -ne 0 ]; then  
    echo "Curl failed with exit code $CURL_EXIT_CODE, retrying in 2 seconds..."  
    sleep 2  
    continue  
  fi  
  
  # Verify the response matches the expected JSON  
  if [ "$RESPONSE" == '{"status":"SERVING"}' ]; then  
    echo "Server is now alive and responding properly!"  
    break  
  fi  
  
  echo "Server not ready yet. Retrying in 2 seconds..."  
  sleep 2  
done  
set -e

docker compose logs
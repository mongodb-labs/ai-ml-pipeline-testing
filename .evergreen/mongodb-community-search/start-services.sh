set -eu
pushd $(dirname ${BASH_SOURCE:-$0}) > /dev/null

source ../../secrets-export.sh
export VOYAGE_QUERY_API_KEY=$VOYAGEAI_API_KEY
export VOYAGE_INDEXING_API_KEY=$VOYAGEAI_API_KEY

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

docker compose down; true
docker compose up -d

# Wait for the healthcheck
URL="http://127.0.0.1:8080/healthcheck"  

echo "Waiting for the server to be alive and respond with the expected status..."  
  
# Wait until the server responds as expected  
while true; do  
  # Make the request and capture the response  
  RESPONSE=$(curl -s "$URL")  
    
  # Check if the response matches the expected value  
  if [ "$RESPONSE" == '{"status":"SERVING"}' ]; then  
    echo "Server is now alive and responding properly!"  
    break  
  fi  
    
  # Wait for a while before trying again  
  echo "Server not ready yet. Retrying in 2 seconds..."  
  sleep 2  
done 
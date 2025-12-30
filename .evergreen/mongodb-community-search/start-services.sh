pushd $(dirname ${BASH_SOURCE:-$0}) > /dev/null

source ../secrets-export.sh
export VOYAGE_QUERY_API_KEY=$VOYAGEAI_API_KEY
export VOYAGE_INDEXING_API_KEY=$VOYAGEAI_API_KEY

# Download sample data if it doesn't exist
if [ ! -f sampledata.archive ]; then
  echo "Downloading sample data..."
  curl https://atlas-education.s3.amazonaws.com/sampledata.archive -o sampledata.archive
else
  echo "Sample data already exists, skipping download."
fi

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

docker compose up -d
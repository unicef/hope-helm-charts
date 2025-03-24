#!/bin/sh

MAX_RETRIES=100
RETRY_INTERVAL=1

# Function to retry a command with a maximum number of attempts
retry() {
  local n=1
  local max=$1
  local interval=$2
  shift 2
  local cmd="$@"

  until [ "$n" -ge "$max" ]
  do
    eval "$cmd" && break || {
      echo "Attempt $n/$max to call '$cmd' failed. Retrying in $interval seconds..."
      n=$((n+1))
      sleep $interval
    }
  done

  if [ "$n" -ge "$max" ]; then
    echo "Max retries reached. Exiting."
    exit 1
  fi
}

# Extract DB_HOST and DB_PORT handling possible @ in the password
DB_HOST=$(echo $DATABASE_URL | rev | sed -e "s|@.*||" | rev | sed -e "s|.*://||" -e "s|:.*||")
DB_PORT=$(echo $DATABASE_URL | sed -n "s|.*:\([0-9]\+\)/.*|\1|p")

retry $MAX_RETRIES $RETRY_INTERVAL "pg_isready -h $DB_HOST -p $DB_PORT"

# Extract VALKEY_HOST and VALKEY_PORT handling possible @ in the password
VALKEY_HOST=$(echo $CELERY_BROKER_URL | rev | sed -e "s|@.*||" | rev | sed -e "s|.*://||" -e "s|:.*||")
VALKEY_PORT=$(echo $CELERY_BROKER_URL | sed -n "s|.*:\([0-9]\+\)/.*|\1|p")

retry $MAX_RETRIES $RETRY_INTERVAL "nc -zv $VALKEY_HOST $VALKEY_PORT"

# Extract ES_HOST and ES_PORT handling possible @ in the password
ES_HOST=$(echo $ELASTICSEARCH_HOST | rev | sed -e "s|@.*||" | rev | sed -e "s|.*://||" -e "s|:.*||")
ES_PORT=$(echo $ELASTICSEARCH_HOST | sed -n "s|.*:\([0-9]\+\)\(/.*\)\?$|\1|p")

retry $MAX_RETRIES $RETRY_INTERVAL "nc -zv $ES_HOST $ES_PORT"

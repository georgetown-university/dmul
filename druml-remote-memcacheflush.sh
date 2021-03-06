#!/bin/bash

# Get Druml dir.
SCRIPT_DIR=$1
shift

# Load includes.
source $SCRIPT_DIR/druml-inc-init.sh

# Display help.
if [[ ${#ARG[@]} -lt 1 || -n $PARAM_HELP ]]
then
  echo "usage: druml remote-memcacheflush [--config=<path>] [--docroot=<path>]"
  echo "                                  [--server=<number>]"
  echo "                                  <environment>"
  exit 1
fi

# Read parameters.
ENV=$(get_environment ${ARG[1]})

# Set variables.
SSH_ARGS=$(get_ssh_args $ENV $PARAM_SERVER)
DRUSH_ALIAS=$(get_drush_alias $ENV)
DEFAULT_SITE=$(get_default_site)

# Read variables and form commands to execute.
echo "=== Flush memcache on the $ENV environment"
echo ""

DOCROOT=$(get_remote_docroot $ENV $PARAM_SERVER)

OUTPUT=$(ssh -Tn $SSH_ARGS "cd $DOCROOT && drush -l $DEFAULT_SITE vget memcache_servers" 2>&1)
RESULT="$?"

# Eixt upon an error.
if [[ $RESULT > 0 ]]; then
  echo "Unable to get memcache servers";
  exit 1
fi

# Flush cache for each server.
COMMANDS="true"
while read -r LINE; do
  if [[ "$LINE" != "memcache_servers:" ]]; then
    SERVER=$(echo $LINE | awk -F':' '{print $1}' | tr -d "\'")
    PORT=$(echo $LINE | awk -F':' '{print $2}' | tr -d "\'")
    COMMANDS="$COMMANDS && /bin/echo -e 'flush_all\nquit' | nc -q1 $SERVER $PORT"
  fi
done <<< "$OUTPUT"
COMMANDS="$COMMANDS;"

# Execute commands.
OUTPUT=$(ssh -Tn $SSH_ARGS "$COMMANDS" 2>&1)
RESULT="$?"

# Eixt upon an error.
if [[ $RESULT > 0 ]]; then
  echo "Problem flushing cache, output:"
  echo "$OUTPUT"
  exit 1
fi

# Check flush status
while read -r LINE; do
  STATUS=$(echo $LINE | awk -F':' '{print $1}' | xargs)
  if [[ $STATUS != *"OK"* ]]; then
    echo "Problem flushing cache, output:"
    echo "$OUTPUT"
    exit 1
  fi
done <<< "$OUTPUT"

echo "Memcache has been flushed!"
exit 0

#!/bin/bash

# Get Druml dir.
SCRIPT_DIR=$1
shift

# Load includes.
source $SCRIPT_DIR/druml-inc-init.sh

# Display help.
if [[ ${#ARG[@]} -lt 2 || -z $PARAM_SITE || -n $PARAM_HELP ]]
then
  echo "usage: druml remote-ac-sitesync [--config=<path>] [--docroot=<path>]"
  echo "                                [--delay=<seconds>]"
  echo "                                [--site=<subsite> | --list=<list>]"
  echo "                                <environment from> <environment to>"
  exit 1
fi

SUBSITE=$PARAM_SITE
ENV_TO=$(get_environment ${ARG[2]})

# Backup target db.
OUTPUT=$(run_script remote-ac-dbbackup --site=$SUBSITE $ENV_TO 2>&1)
RESULT="$?"
echo "$OUTPUT"
if [[ $RESULT > 0 ]]; then
  exit 1
fi

# Copy files.
OUTPUT=$(run_script remote-filesync $PROXY_PARAMS $PROXY_ARGS 2>&1)
RESULT="$?"
echo "$OUTPUT"
if [[ $RESULT > 0 ]]; then
  exit 1
fi
echo ""

# Copy DB.
OUTPUT=$(run_script remote-ac-dbsync $PROXY_PARAMS $PROXY_ARGS 2>&1)
RESULT="$?"
echo "$OUTPUT"
if [[ $RESULT > 0 ]]; then
  exit 1
fi
echo ""

# Flush Memcache.
OUTPUT=$(run_script remote-memcacheflush $ENV_TO 2>&1)
RESULT="$?"
echo "$OUTPUT"
if [[ $RESULT > 0 ]]; then
  exit 1
fi
echo ""

# Flush Drupal cache.
OUTPUT=$(run_script remote-drush --site=$SUBSITE $ENV_TO "cc all" 2>&1)
RESULT="$?"
echo "$OUTPUT"
if [[ $RESULT > 0 ]]; then
  exit 1
fi

# TODO: Flush Varnish cache.

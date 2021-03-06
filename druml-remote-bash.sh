#!/bin/bash

# Get Druml dir.
SCRIPT_DIR=$1
shift

# Load includes.
source $SCRIPT_DIR/druml-inc-init.sh

# Display help.
if [[ ${#ARG[@]} -lt 2 || -n $PARAM_HELP ]]
then
  echo "usage: druml remote-bash [--config=<path>] [--docroot=<path>]"
  echo "                         [--server=<number>]"
  echo "                         <environment> <commands>"
  echo ""
  echo "You can use following variables in a command:"
  echo " @DOCROOT - subsite docroot"
  echo " @LOG     - logs dir"
  exit 1
fi

# Read parameters.
ENV=$(get_environment ${ARG[1]})

# Set variables.
SSH_ARGS=$(get_ssh_args $ENV $PARAM_SERVER)
DRUSH_ALIAS=$(get_drush_alias $ENV $PARAM_SERVER)

# Read variables and form commands to execute.
echo "=== Execute bash commands on the $ENV environment"
echo "Commands to be executed:"

# Read commands.
COMMANDS=""
I=1
for CMD in ${ARG[@]}
do
  if [[ $I -gt 1 && -n ${ARG[$I]} ]]
  then
    if [[ -z $COMMANDS ]]; then
      COMMANDS="${ARG[$I]}"
    else
      COMMANDS="$COMMANDS && ${ARG[$I]}"
    fi
    echo "${ARG[$I]}";
  fi
  I=$((I+1))
done
COMMANDS="$COMMANDS;"

# Replace variables.
COMMANDS=${COMMANDS/@DOCROOT/$(get_remote_docroot $ENV $PARAM_SERVER)}
COMMANDS=${COMMANDS/@LOG/$(get_remote_log $ENV $PARAM_SERVER)}

# Output commands.
echo ""

# Execute bash commands.
OUTPUT=$(ssh -Tn $SSH_ARGS "$COMMANDS" 2>&1)
RESULT="$?"

echo "Result:"
echo "$OUTPUT"

# Eixt upon an error.
if [[ $RESULT > 0 ]]; then
  exit 1
fi

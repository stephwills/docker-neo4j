#!/bin/bash

# A script for use as a Docker/Kubernetes 'readiness probe'.
# Used to determine whether the database is 'ready'.
#
# We assume the following environment variables exist: -
#
#   NEO4J_dbms_directories_logs
#   IMPORT_DIRECTORY
#
# This code inspects the debug log looking for a line that
# contains 'Database graph.db is ready'. The file is expected
# to be called $NEO4J_dbms_directories_logs/debug.log
#
# If the line is found then we check for the 'first' and 'always' script
# execution.

# Not started if there's no file
DEBUG_FILE=$NEO4J_dbms_directories_logs/debug.log
if [ ! -f "$DEBUG_FILE" ]; then
  echo "Database not ready (no $DEBUG_FILE)"
  exit 1
fi

# Does the line exist?
READY=$(grep -c "Database graph.db is ready." < "$DEBUG_FILE")
if [ "$READY" -eq "0" ]; then
  echo "Database not ready (according to $DEBUG_FILE)"
  exit 1
fi

# If there's no 'once' we're not 'live'
ONCE_EXECUTED_FILE="$IMPORT_DIRECTORY"/once.executed
if [ ! -f "$ONCE_EXECUTED_FILE" ]; then
  echo "Database not ready (no $ONCE_EXECUTED_FILE)"
  exit 1
fi

# If there's no 'always' we're not 'live'
ALWAYS_EXECUTED_FILE="$IMPORT_DIRECTORY"/always.executed
if [ ! -f "$ALWAYS_EXECUTED_FILE" ]; then
  echo "Database not ready (no $ALWAYS_EXECUTED_FILE)"
  exit 1
fi

# Graph Database is 'Ready' if we get here...
# Nothing to do - return value of zero is all that's needed.
echo "Database ready"

#!/usr/bin/env bash

# Order of execution...
#
# 1. We always run the LEGACY_SCRIPT script (if present)
#    ...but we should stop using the LEGACY_SCRIPT
# 2. We run the ONCE_SCRIPT on first execution (if present)
# 3. We always run the ALWAYS_SCRIPT (if present)
#
# Normally there's a LEGACY script or we're using the
# ONCE or ALWAYS scripts. LEGACY is supported for backwards compatibility.
#
# Determining whether this is the first execution relies on a persistent volume
# and here we use the IMPORT_DIRECTORY. If it is not defined or the volume it
# points to is not persisted then all scripts will always be executed.

ME=cypher-runner.sh

# The legacy scriot is always executed.
# It is deprecated and users should use the `.once` or `.always` scripts.
LEGACY_SCRIPT="$CYPHER_ROOT"/cypher-script/cypher.script
ONCE_SCRIPT="$CYPHER_ROOT"/cypher-script/cypher-script.once
ALWAYS_SCRIPT="$CYPHER_ROOT"/cypher-script/cypher-script.always
# The 'we have executed' file. We 'touch' this at the end of this script.
# If present (in the IMPORT_DIRECTORY) this prevents us from running the
# '.once' script.
# The import directory variable may not exist - if it doesn't
# then will end up running all the scripts on each container start
# (because we only 'touch' this file if the IMPORT_DIRECTORY exists).
EXECUTED_FILE="$IMPORT_DIRECTORY"/cypher-runner.executed

echo "($ME) $(date) Starting (IMPORT_DIRECTORY=$IMPORT_DIRECTORY)..."

if [ -z "$NEO4J_USERNAME" ]
then
    echo "($ME) $(date) No NEO4J_USERNAME. Can't run without this."
    exit 0
fi
if [ -z "$NEO4J_PASSWORD" ]
then
    echo "($ME) $(date) No NEO4J_PASSWORD. Can't run without this."
    exit 0
fi

echo "($ME) $(date) NEO4J_USERNAME=$NEO4J_USERNAME"
echo "($ME) $(date) NEO4J_PASSWORD=$NEO4J_PASSWORD"
echo "($ME) $(date) LEGACY_SCRIPT=$LEGACY_SCRIPT"
echo "($ME) $(date) ONCE_SCRIPT=$ONCE_SCRIPT"
echo "($ME) $(date) ALWAYS_SCRIPT=$ALWAYS_SCRIPT"
echo "($ME) $(date) EXECUTED_FILE=$EXECUTED_FILE"

# Configurable sleep prior to the first cypher command.
# Needs to be sufficient to allow the server to start accepting connections.
SLEEP_TIME=${CYPHER_PRE_NEO4J_SLEEP:-60}
echo "($ME) $(date) Pre-cypher pause ($SLEEP_TIME seconds)..."
sleep "$SLEEP_TIME"

# Attempt to change the initial password...
# Added during work on k8s and OpenShift deployment
# (password didn't appear to be set)
if [[ ! -f "$EXECUTED_FILE" ]]; then
  echo "($ME) $(date) Setting neo4j password..."
  /var/lib/neo4j/bin/cypher-shell -u neo4j -p neo4j "CALL dbms.changePassword('$NEO4J_PASSWORD')" || true
fi

# Always run the LEGACY_SCRIPT if it exists)...
if [ -f "$LEGACY_SCRIPT" ]; then
    echo "($ME) $(date) Trying legacy $LEGACY_SCRIPT..."
    echo "[SCRIPT BEGIN]"
    cat $LEGACY_SCRIPT
    echo "[SCRIPT END]"
    until /var/lib/neo4j/bin/cypher-shell < "$LEGACY_SCRIPT"
    do
        echo "($ME) $(date) No joy, waiting..."
        sleep 4
    done
    echo "($ME) $(date) Script executed."
else
    echo "($ME) $(date) No legacy script."
fi

# Run the ONCE_SCRIPT
# (if the EXECUTE_FILE is not present)...
if [[ ! -f "$EXECUTED_FILE" && -f "$ONCE_SCRIPT" ]]; then
    echo "($ME) $(date) Trying $ONCE_SCRIPT..."
    echo "[SCRIPT BEGIN]"
    cat $ONCE_SCRIPT
    echo "[SCRIPT END]"
    until /var/lib/neo4j/bin/cypher-shell < "$ONCE_SCRIPT"
    do
        echo "($ME) $(date) No joy, waiting..."
        sleep 4
    done
    echo "($ME) $(date) .once script executed."
else
    echo "($ME) $(date) No .once script (or restarted)."
fi

# Always run the ALWAYS_SCRIPT...
if [ -f "$ALWAYS_SCRIPT" ]; then
    echo "($ME) $(date) Trying $ALWAYS_SCRIPT..."
    echo "[SCRIPT BEGIN]"
    cat $ALWAYS_SCRIPT
    echo "[SCRIPT END]"
    until /var/lib/neo4j/bin/cypher-shell < "$ALWAYS_SCRIPT"
    do
        echo "($ME) $(date) No joy, waiting..."
        sleep 4
    done
    echo "($ME) $(date) .always script executed."
else
    echo "($ME) $(date) No .always script."
fi

# Touch a 'cypher-runner.executed' file (if the IMPORT_DIRECTORY exists)
# This is used to prevent us from running the '.once' script on re-boot
# but relies on the IMPORT_DIRECTORY being persisted between reboots.
if [ -n "$IMPORT_DIRECTORY" ]; then
  echo "($ME) $(date) Touching $EXECUTED_FILE..."
  touch "$EXECUTED_FILE"
fi

echo "($ME) $(date) Finished."

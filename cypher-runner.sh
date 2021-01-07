#!/usr/bin/env bash

# Order of execution...
#
# 1. We run the ONCE_SCRIPT on first execution (if present)
# 2. We always run the ALWAYS_SCRIPT (if present)
#
# Expects the following environment variables: -
#
#   CYPHER_PRE_NEO4J_SLEEP
#   CYPHER_ROOT
#   GRAPH_PASSWORD

ME=cypher-runner.sh

# The graph user password is required as an environment variable.
# The user is expected to be 'neo4j'.
if [ -z "$GRAPH_PASSWORD" ]
then
    echo "($ME) $(date) No GRAPH_PASSWORD. Can't run without this."
    exit 0
fi

# The 'once' and 'always' cypher scripts
CYPHER_PATH="$CYPHER_ROOT/cypher-script"
ONCE_SCRIPT="$CYPHER_PATH/cypher-script.once"
ALWAYS_SCRIPT="$CYPHER_PATH/cypher-script.always"

# Files created (touched) when the 'first' script is run
# and when the 'always' script is run. These files are created
# even if there are no associated scripts. The 'always' file
# is erased each time we're executed and re-created after it's re-executed.
ONCE_EXECUTED_FILE="$CYPHER_PATH/once.executed"
ALWAYS_EXECUTED_FILE="$CYPHER_PATH/always.executed"

# Always remove the ALWAYS_EXECUTED_FILE.
# We re-create this when we've run the always script
# (which happens every time we start)
rm -f "$ALWAYS_EXECUTED_FILE" || true

echo "($ME) $(date) GRAPH_PASSWORD=$GRAPH_PASSWORD"
echo "($ME) $(date) ONCE_SCRIPT=$ONCE_SCRIPT"
echo "($ME) $(date) ALWAYS_SCRIPT=$ALWAYS_SCRIPT"
echo "($ME) $(date) ONCE_EXECUTED_FILE=$ONCE_EXECUTED_FILE"
echo "($ME) $(date) ALWAYS_EXECUTED_FILE=$ALWAYS_EXECUTED_FILE"

# Configurable sleep prior to the first cypher command.
# Needs to be sufficient to allow the server to start accepting connections.
SLEEP_TIME=${CYPHER_PRE_NEO4J_SLEEP:-60}
echo "($ME) $(date) Pre-cypher pause ($SLEEP_TIME seconds)..."
sleep "$SLEEP_TIME"

# Run the ONCE_SCRIPT
# (if the ONCE_EXECUTED_FILE is not present)...
if [[ ! -f "$ONCE_EXECUTED_FILE" && -f "$ONCE_SCRIPT" ]]; then
    echo "($ME) $(date) Trying $ONCE_SCRIPT..."
    echo "[SCRIPT BEGIN]"
    cat "$ONCE_SCRIPT"
    echo "[SCRIPT END]"
    until /var/lib/neo4j/bin/cypher-shell -u neo4j -p "$GRAPH_PASSWORD" < "$ONCE_SCRIPT"
    do
        echo "($ME) $(date) No joy, waiting..."
        sleep 4
    done
    echo "($ME) $(date) .once script executed."
else
    echo "($ME) $(date) No .once script (or not first incarnation)."
fi
echo "($ME) $(date) Touching $ONCE_EXECUTED_FILE..."
touch "$ONCE_EXECUTED_FILE"

# Always run the ALWAYS_SCRIPT...
if [ -f "$ALWAYS_SCRIPT" ]; then
    echo "($ME) $(date) Trying $ALWAYS_SCRIPT..."
    echo "[SCRIPT BEGIN]"
    cat "$ALWAYS_SCRIPT"
    echo "[SCRIPT END]"
    until /var/lib/neo4j/bin/cypher-shell -u neo4j -p "$GRAPH_PASSWORD" < "$ALWAYS_SCRIPT"
    do
        echo "($ME) $(date) No joy, waiting..."
        sleep 4
    done
    echo "($ME) $(date) .always script executed."
else
    echo "($ME) $(date) No .always script."
fi
echo "($ME) $(date) Touching $ALWAYS_EXECUTED_FILE..."
touch "$ALWAYS_EXECUTED_FILE"

echo "($ME) $(date) Finished."

#!/bin/sh

# We need some key environment variables
# before we do anything sensible...
#
# AWS_*       Are AWS credentials for accessing the S3 bucket
# SYNC_PATH   Is the directory to synchronise S3 content with
#             Typically the data-loader directory
# GRAPH_WIPE  If 'yes' then all data is erased, forcing
#             a resync with S3 and a reload of the Graph data

: "${AWS_ACCESS_KEY_ID?Need to set AWS_ACCESS_KEY_ID}"
: "${AWS_SECRET_ACCESS_KEY?Need to set AWS_SECRET_ACCESS_KEY}"
: "${AWS_BUCKET?Need to set AWS_BUCKET}"
: "${AWS_BUCKET_PATH?Need to set AWS_BUCKET_PATH}"
: "${SYNC_PATH?Need to set SYNC_PATH}"
: "${GRAPH_WIPE?Need to set GRAPH_WIPE}"

# If GRAPH_WIPE is 'yes' then the /data directory is
# erased prior to running the S3 sync.
if [ "$GRAPH_WIPE" = "yes" ]; then
  echo "Wiping graph data (GRAPH_WIPE=$GRAPH_WIPE)..."
  rm -rf /data/*
else
  echo "Preserving exisiting graph data (GRAPH_WIPE=$GRAPH_WIPE)"
fi

echo "Synchronising S3 path (${AWS_BUCKET}/${AWS_BUCKET_PATH})..."
aws s3 sync "s3://${AWS_BUCKET}/${AWS_BUCKET_PATH}" "/data/${SYNC_PATH}"
# Just in case the above fails, at least create a data directory...
mkdir -p /data/data

# If there's 'once' or 'always' content then place it
# in the expected location for the corresponding cypher scripts.
cypher_path="$CYPHER_ROOT/cypher-script"
if [ "$CYPHER_ONCE_CONTENT" ]
then
  cypher_file=cypher-script.once
  echo "Writing $cypher_path/$cypher_file..."
  mkdir -p "$cypher_path"
  chmod 0755 "$cypher_path"
  echo "$CYPHER_ONCE_CONTENT" > "$cypher_path/$cypher_file"
  chmod 0755 "$cypher_path/$cypher_file"
fi
if [ "$CYPHER_ALWAYS_CONTENT" ]
then
  cypher_file=cypher-script.always
  echo "Writing $cypher_path/$cypher_file..."
  mkdir -p "$cypher_path"
  chmod 0755 "$cypher_path"
  echo "$CYPHER_ALWAYS_CONTENT" > "$cypher_path/$cypher_file"
  chmod 0755 "$cypher_path/$cypher_file"
fi

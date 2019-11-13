#!/bin/sh

# We need some key environment variables
# before we do anything sensible...

: "${AWS_ACCESS_KEY_ID?Need to set AWS_ACCESS_KEY_ID}"
: "${AWS_SECRET_ACCESS_KEY?Need to set AWS_SECRET_ACCESS_KEY}"
: "${AWS_BUCKET?Need to set AWS_BUCKET}"
: "${AWS_BUCKET_PATH?Need to set AWS_BUCKET_PATH}"
: "${SYNC_PATH?Need to set SYNC_PATH}"
: "${GRAPH_WIPE?Need to set GRAPH_WIPE}"

# If GRAPH_WIPE is 'yes' then the /data directory is
# erased prior to running the S3 sync.
if [ "$GRAPH_WIPE" = "yes" ]; then
  rm -rf /data/*
fi
aws s3 sync "s3://${AWS_BUCKET}/${AWS_BUCKET_PATH}" "/data/${SYNC_PATH}"

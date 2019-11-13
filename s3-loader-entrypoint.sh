#!/bin/sh

# We need some key environment variables
# before we do anything sensible...

: "${AWS_ACCESS_KEY_ID?Need to set AWS_ACCESS_KEY_ID}"
: "${AWS_SECRET_ACCESS_KEY?Need to set AWS_SECRET_ACCESS_KEY}"
: "${AWS_BUCKET?Need to set AWS_BUCKET}"
: "${AWS_BUCKET_PATH?Need to set AWS_BUCKET_PATH}"
: "${SYNC_PATH?Need to set SYNC_PATH}"

aws s3 sync "s3://${AWS_BUCKET}/${AWS_BUCKET_PATH}" "/data/${SYNC_PATH}"

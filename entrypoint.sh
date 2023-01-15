#!/usr/bin/env bash

set -e

# Defaults
: ${AWS_S3_AUTHFILE:='/root/.s3fs'}
: ${AWS_S3_MOUNTPOINT:='/opt/data/hls'}


# If no command specified, print error
[ "$1" == "" ] && set -- "$@" bash -c 'echo "Error: Please specify a command to run."; exit 128'

# Configuration checks
if [ -z "$AWS_S3_URL" ]; then
    echo "Error: AWS_S3_URL is not specified"
    exit 128
fi

if [ -z "$AWS_S3_BUCKET_NAME" ]; then
    echo "Error: AWS_S3_BUCKET_NAME is not specified"
    exit 128
fi

if [ ! -f "${AWS_S3_AUTHFILE}" ] && [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "Error: AWS_ACCESS_KEY_ID not specified, or ${AWS_S3_AUTHFILE} not provided"
    exit 128
fi

if [ ! -f "${AWS_S3_AUTHFILE}" ] && [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Error: AWS_SECRET_ACCESS_KEY not specified, or ${AWS_S3_AUTHFILE} not provided"
    exit 128
fi

# Write auth file if it does not exist
if [ ! -f "${AWS_S3_AUTHFILE}" ]; then
   echo "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" > ${AWS_S3_AUTHFILE}
   chmod 400 ${AWS_S3_AUTHFILE}
fi

echo "==> Mounting S3 Filesystem ${AWS_S3_MOUNTPOINT}"
# mkdir -p ${AWS_S3_MOUNTPOINT}

# s3fs mount command
# s3fs -d -o passwd_file=${AWS_S3_AUTHFILE} -o use_path_request_style -o url=${AWS_S3_URL} -o allow_other -o umask=000 ${AWS_S3_BUCKET_NAME} ${AWS_S3_MOUNTPOINT} 2>>/dev/stdout

# RUN NGINX
nginx

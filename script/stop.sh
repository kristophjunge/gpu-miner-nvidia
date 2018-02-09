#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV_FILE=${SCRIPT_DIR}/../.env
if [ ! -f ${ENV_FILE} ]; then
    echo ".env file not present, exiting"
    exit 1
fi
source ${ENV_FILE}

echo "`date` Stopping"

# Stop nvidia docker compose
cd ${SCRIPT_DIR}/..
if [ -z "${GPUMINERNVIDIA_MODE}" ]; then
    docker-compose -f docker-compose.yml stop
else
    docker-compose -f docker-compose.yml -f mode/${GPUMINERNVIDIA_MODE}/docker-compose.yml stop
fi

echo "`date` Stopped"
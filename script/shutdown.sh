#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV_FILE=${SCRIPT_DIR}/../.env
if [ ! -f ${ENV_FILE} ]; then
    echo ".env file not present, exiting"
    exit 1
fi
source ${ENV_FILE}

echo "`date` Reboot sequence started"

echo "`date` Stopping miner"
${SCRIPT_DIR}/stop.sh

echo "`date` Waiting ${GPUMINERNVIDIA_SHUTDOWN_DELAY}s before shutdown"
sleep ${GPUMINERNVIDIA_SHUTDOWN_DELAY}

echo "`date` Shutdown"
/sbin/shutdown

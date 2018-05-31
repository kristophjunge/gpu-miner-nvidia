#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV_FILE=${SCRIPT_DIR}/../.env
if [ ! -f ${ENV_FILE} ]; then
    echo ".env file not present, exiting"
    exit 1
fi
source ${ENV_FILE}

echo "`date` Starting in mode '${GPUMINERNVIDIA_MODE}'"

# GPU Setup

export DISPLAY=:0
export XAUTHORITY=~/.Xauthority
export LC_ALL="en_US.utf-8"

echo "`date` Configure xserver"
nvidia-xconfig --enable-all-gpus --cool-bits=28 --allow-empty-initial-configuration
# @TODO Restart xserver

# Enable persistence mode
nvidia-smi --persistence-mode=1

if [ ! -z "${GPUMINERNVIDIA_MODE}" ]; then

    OC_PROFILE_CONFIG=${SCRIPT_DIR}/../mode/${GPUMINERNVIDIA_MODE}/oc-profile

    if [ ! -f ${OC_PROFILE_CONFIG} ]; then

        echo "`date` oc-profile.sh not found for mode ${GPUMINERNVIDIA_MODE}"

    else

        echo "`date` Waiting ${GPUMINERNVIDIA_OC_DELAY}s before applying OC"
        sleep ${GPUMINERNVIDIA_OC_DELAY}

        MEMORY_CLOCK_OFFSET=0
        CPU_CLOCK_OFFSET=0
        POWER_LIMIT=0
        FAN_SPEED=0

        source ${OC_PROFILE_CONFIG}

        echo "`date` Applying OC (Memory Clock Offset: ${MEMORY_CLOCK_OFFSET}, CPU Clock Offset: ${CPU_CLOCK_OFFSET}, Power Limit: ${POWER_LIMIT})"

        nvidia-smi --query-gpu=index --format=csv,noheader | while read i
        do
            nvidia-settings \
                --assign "[gpu:${i}]/GPUGraphicsClockOffset[3]=${CPU_CLOCK_OFFSET}" \
                --assign "[gpu:${i}]/GPUMemoryTransferRateOffset[3]=${MEMORY_CLOCK_OFFSET}"

            if [ "${FAN_SPEED}" -gt 40 ]; then
                nvidia-settings \
                    --assign "[gpu:${i}]/GPUFanControlState=1" \
                    --assign "[fan:${i}]/GPUTargetFanSpeed=${FAN_SPEED}"
            fi

            nvidia-smi -i ${i} -pl ${POWER_LIMIT}
        done

    fi

fi

echo "`date` Warm up nvidia-docker"
docker run --rm nvidia/cuda nvidia-smi

echo "`date` Waiting ${GPUMINERNVIDIA_STARTUP_DELAY}s before starting"
sleep ${GPUMINERNVIDIA_STARTUP_DELAY}

echo "`date` Starting"

# Start docker-compose
cd ${SCRIPT_DIR}/../
if [ -z "${GPUMINERNVIDIA_MODE}" ]; then
    docker-compose -f ${SCRIPT_DIR}/../docker-compose.yml up --build --force-recreate --remove-orphans
else
    docker-compose -f ${SCRIPT_DIR}/../docker-compose.yml -f ${SCRIPT_DIR}/../mode/${GPUMINERNVIDIA_MODE}/docker-compose.yml up --build --force-recreate --remove-orphans
fi

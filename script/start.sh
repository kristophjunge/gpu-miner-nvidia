#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV_FILE=${SCRIPT_DIR}/../.env
if [ ! -f ${ENV_FILE} ]; then
    echo ".env file not present, exiting"
    exit 1
fi
source ${ENV_FILE}

export DISPLAY=:0
export XAUTHORITY=/var/run/lightdm/root/:0

echo "`date` Starting"

# Connect to VPN

if [ -n "${VPN_ID}" ]; then
    echo "`date` Connect to VPN"
    #nmcli con up id ${VPN_ID}
fi

# GPU Setup

echo "`date` Configure xserver"
sudo nvidia-xconfig --enable-all-gpus --cool-bits=28 --allow-empty-initial-configuration
# @TODO Restart xserver

if [ ! -z "${GPUMINERNVIDIA_MODE}" ]; then

    OC_PROFILE_CONFIG=${SCRIPT_DIR}/mode/${GPUMINERNVIDIA_MODE}/oc-profile.sh

    if [ ! -f ${OC_PROFILE_CONFIG} ]; then

        echo "`date` oc-profile.sh not found for mode ${GPUMINERNVIDIA_MODE}"

    else

        echo "`date` Waiting ${OC_DELAY}s before applying OC"
        sleep ${OC_DELAY}

        echo "`date` Applying OC"

        MEMORY_CLOCK=0
        CPU_CLOCK=0
        POWER_LIMIT=0

        source ${OC_PROFILE_CONFIG}

        nvidia-smi --query-gpu=index --format=csv,noheader | while read i
        do
            #/run/user/1000/gdm/Xauthority
            #DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 nvidia-settings -a [gpu:0]/GPUFanControlState=1
            #DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 nvidia-settings -a [fan:0]/GPUTargetFanSpeed=75
            nvidia-settings && \
                --assign "[gpu:${i}]/GPUGraphicsClockOffset[3]=${CPU_CLOCK}" && \
                --assign "[gpu:${i}]/GPUMemoryTransferRateOffset[3]=${MEMORY_CLOCK}"
            nvidia-smi -i ${i} -pl ${POWER_LIMIT}
        done

    fi

fi

echo "`date` Waiting ${STARTUP_DELAY}s before starting"
sleep ${STARTUP_DELAY}

echo "`date` Warm up nvidia-docker"
docker run --rm nvidia/cuda nvidia-smi

# Start nvidia-docker-compose
cd ${SCRIPT_DIR}/..

if [ -z "${GPUMINERNVIDIA_MODE}" ]; then
    docker-compose -f docker-compose.yml up && \
        --build && \
        --force-recreate && \
        --remove-orphans
else
    docker-compose -f docker-compose.yml -f mode/${GPUMINERNVIDIA_MODE}/docker-compose.yml up && \
        --build && \
        --force-recreate && \
        --remove-orphans
fi

echo "`date` Started"

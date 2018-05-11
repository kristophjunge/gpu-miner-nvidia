#!/bin/bash

set -e

if [ -z "${1}" ]; then
    echo "Missing target host argument!"
    exit
fi

TARGET_HOST=${1}
PRESERVE_PATHS=".env mode/dcr/oc-profile mode/eth/oc-profile mode/zec/oc-profile"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_NAME="gpu-miner-nvidia"
TARGET_DIR="/opt/${PROJECT_NAME}"
GIT_CHANGED=$(git diff-index --name-only HEAD --)
GIT_BRANCH=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')

echo -e "Deployment to host \e[93m${TARGET_HOST}\e[39m!"
echo

if [ "${GIT_BRANCH}" == "master" ]; then

    if [ -n "${GIT_CHANGED}" ]; then
        git status -s
        echo
        echo -e "You are on 'master' branch and have local changes. Do you want to \e[93mcommit\e[39m?"
        read -p "Press 'y': " -n 1 -r
        echo
        echo
        if [[ ${REPLY} =~ ^[Yy]$ ]]
        then
            echo "Committing changes..."
            git commit -a -m "WIP"
            echo ""
        fi
    fi

    GIT_NOT_PUSHED_COMMITS=$(git log origin/master..master --oneline | wc -l)

    if [ "${GIT_NOT_PUSHED_COMMITS}" -gt "0" ]; then
        echo -e "You have ${GIT_NOT_PUSHED_COMMITS} unpushed commit(s). Do you want to \e[93mpush\e[39m?"
        read -p "Press 'y': " -n 1 -r
        echo
        echo
        if [[ ${REPLY} =~ ^[Yy]$ ]]
        then
            echo "Pushing changes..."
            git push origin master
            echo ""
        fi
    fi

fi

TIMESTAMP=$(date +%Y%m%d%H%M%S)
ARCHIVE_NAME="deploy-${PROJECT_NAME}-${TIMESTAMP}.tar.gz"

echo "Compressing files..."
git archive --format=tar.gz master > /tmp/${ARCHIVE_NAME}
echo

echo "Uploading archive..."
scp /tmp/${ARCHIVE_NAME} ${TARGET_HOST}:/tmp/${ARCHIVE_NAME}
echo

echo "Backing up paths to preserve..."
PRESERVE_PATHS_DIR="/tmp/deploy-preserved-${PROJECT_NAME}"
ssh ${TARGET_HOST} /bin/bash << EOF
    mkdir -p ${PRESERVE_PATHS_DIR}
    for i in ${PRESERVE_PATHS}
    do
        mkdir -p \$(dirname "${PRESERVE_PATHS_DIR}/\${i}")
        cp -rfv ${TARGET_DIR}/\${i} ${PRESERVE_PATHS_DIR}/\${i} || true
    done
EOF
echo

RESTART_SERVICES=0
echo -e "Do you want to \e[93mrestart the services\e[39m during deployment?"
read -p "Press 'y': " -n 1 -r
echo
echo
if [[ ${REPLY} =~ ^[Yy]$ ]]
then
    RESTART_SERVICES=1
fi

ssh ${TARGET_HOST} /bin/bash << EOF
    if [[ ${RESTART_SERVICES} = "1" ]]
    then
        echo "Stopping services..."
        service gpu-miner-nivida stop
        echo
    fi

    echo "Wiping target directory..."
    rm -rf ${TARGET_DIR}/*
    echo

    echo "Extracting files..."
    mkdir -p ${TARGET_DIR}
    tar -xzf /tmp/${ARCHIVE_NAME} -C ${TARGET_DIR}
    rm /tmp/${ARCHIVE_NAME}
    echo

    echo "Restoring preserved paths..."
    shopt -s dotglob && cp -rfa ${PRESERVE_PATHS_DIR}/* ${TARGET_DIR}/
    rm -rf ${PRESERVE_PATHS_DIR}
    echo

    echo "Importing crontab for root..."
    crontab ${TARGET_DIR}/root.crontab
    echo

    if [[ ${RESTART_SERVICES} = "1" ]]
    then
        echo "Starting services..."
        service gpu-miner-nivida start
        echo
    fi
EOF

echo -e "\e[94m                    ##        ."
echo "              ## ## ##       =="
echo "           ## ## ## ##      ==="
echo "       /\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\___/ ==="
echo "  ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~"
echo "       \______ o          __/"
echo "         \    \        __/"
echo "          \____\______/"
echo -e "\e[39m"
echo -e "\e[92mDeployment to ${TARGET_HOST} successful!\e[39m"

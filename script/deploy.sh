#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV_FILE=${SCRIPT_DIR}/../.env
if [ ! -f ${ENV_FILE} ]; then
    echo ".env file not present, exiting"
    exit 1
fi
source ${ENV_FILE}

echo ""
echo "Updating docker host..."
echo ""
echo "                    ##        ."
echo "              ## ## ##       =="
echo "           ## ## ## ##      ==="
echo "       /\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\"\___/ ==="
echo "  ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~"
echo "       \______ o          __/"
echo "         \    \        __/"
echo "          \____\______/"
echo ""

# Change working dir
cd ${SCRIPT_DIR}/..

# Remember last commit
LAST_COMMIT=`git rev-parse HEAD`

echo ""
echo "Updating git repo..."
echo ""
git pull origin master

echo ""
echo "Checking out previous commit..."
echo ""
git checkout ${LAST_COMMIT}

${SCRIPT_DIR}/stop.sh

echo ""
echo "Checking out latest commit..."
echo ""
git checkout master

${SCRIPT_DIR}/start.sh

echo ""
echo "Done"

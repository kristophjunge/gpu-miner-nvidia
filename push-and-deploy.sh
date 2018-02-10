#!/bin/bash

set -e

TARGET_HOST=${TARGET_HOST:="gpuminernvidia1"}

echo "Committing local changes..."
echo ""

git pull origin master

git add .
git status

git commit -m "WIP"
git push origin master

ssh ${TARGET_HOST} "/opt/gpu-miner-nvidia/script/deploy.sh"

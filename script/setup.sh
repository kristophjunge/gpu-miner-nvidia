#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt-get update
sudo apt-get upgrade



sudo apt install -y --no-install-recommends build-essential
wget -o nvidia.run http://us.download.nvidia.com/XFree86/Linux-x86_64/390.25/NVIDIA-Linux-x86_64-390.25.run
chmod +x nvidia.run




echo "Set default startup mode to console"
sudo systemctl set-default multi-user.target
echo "Install minimal xserver"
sudo apt install xorg xserver-xorg-legacy xserver-xorg-video-dummy



echo "Install openvpn"
sudo apt install -y --no-install-recommends openvpn
#/etc/default/openvpn
#AUTOSTART="all"
#/etc/openvpn/
#sudo openvpn /etc/openvpn/config.ovpn

echo "Remove previous docker installations"
sudo apt-get remove --purge -y docker docker-engine docker.io

echo "Install docker"
sudo apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
sudo apt-get update
sudo apt-get install docker-ce docker-compose
sudo apt-get clean
sudo groupadd -f docker
sudo usermod -aG docker ${USER}

echo "Install nvidia-docker"
# If you have nvidia-docker 1.0 installed: we need to remove it and all existing GPU containers
docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f
sudo apt-get purge -y nvidia-docker
# Add the package repositories
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \\
sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/ubuntu16.04/amd64/nvidia-docker.list | \\
sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
# Install nvidia-docker2 and reload the Docker daemon configuration
sudo apt-get install -y nvidia-docker2
sudo pkill -SIGHUP dockerd

echo "Configure nvidia-docker"
cat << EOF > /etc/docker/daemon.json
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": [ ]
        }
    }
}
EOF
echo "Warm up nvidia-docker"
docker run --rm nvidia/cuda nvidia-smi

echo "Configure xserver"
export DISPLAY=:0
export XAUTHORITY=/var/run/lightdm/root/:0
sudo nvidia-xconfig --enable-all-gpus --cool-bits=28 --allow-empty-initial-configuration
#/etc/X11/xorg.conf
#    Option         "AllowEmptyInitialConfiguration" "True"
#    Option         "ConnectedMonitor" "DFP-0"
#    Option         "Interactive" "False"
#    Option         "Coolbits" "24"

echo "Install gpu-miner-nvidia service"
sudo cp ./gpu-miner-nvidia.service /etc/systemd/system/gpu-miner-nvidia.service
sudo systemctl daemon-reload
sudo systemctl enable gpu-miner-nvidia.service
sudo service gpu-miner-nvidia start

echo "Setup log file"
sudo mkdir -p /var/log/gpu-miner-nvidia
sudo touch /var/log/gpu-miner-nvidia/gpu-miner-nvidia.log

#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt update
sudo apt upgrade

# Tools
echo "Install tools"
sudo apt install -y --no-install-recommends build-essential apt-transport-https ca-certificates curl software-properties-common htop dialog

echo "Install minimal xserver"
# Install x server before Nvidia driver to allow detection of Xorg locations.
sudo apt install -y --no-install-recommends xorg xserver-xorg-legacy #xserver-xorg-video-dummy

# Disable nouveau driver
if [ "$(lsmod | grep nouveau | wc -l)" -gt 0 ]; then
    dialog --yesno "The Nouveau driver is loaded! \n\nDo you want to disable it?" 0 0
    answer=$?
    clear
    if [ ${answer} -eq 0 ]; then
        echo "Disabling Nouveau driver"
        sudo bash -c "echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
        sudo bash -c "echo options nouveau modeset=0 >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
        sudo update-initramfs -u
        echo "The Nouveau driver was disabled! Please reboot and start the script again"
        exit
    fi
fi

# Nvidia driver
if [ ! "$(which nvidia-settings)" ]; then
    dialog --yesno "The Nvidia driver is not installed! Do you want to install it?" 0 0
    answer=$?
    clear
    if [ ${answer} -eq 0 ]; then
        echo "Download Nvidia driver"
        wget -O nvidia.run http://us.download.nvidia.com/XFree86/Linux-x86_64/390.48/NVIDIA-Linux-x86_64-390.48.run
        echo "Install Nvidia driver"
        chmod +x nvidia.run
        ./nvidia.run
        echo "The Nvidia driver was installed! Please reboot and start the script again."
        exit
    fi
fi

echo "Setup .bashrc"
cat << EOF >> ~/.bashrc

# GPU Miner Nvidia
export DISPLAY=:0
export XAUTHORITY=~/.Xauthority
export LC_ALL="en_US.utf-8"
EOF

echo "Remove previous docker installations"
sudo apt remove --purge -y docker docker-engine docker.io

echo "Install docker"
# Install ubuntu version to be compatible with nvidia-docker
sudo apt install -y --no-install-recommends docker.io
sudo systemctl enable docker
sudo systemctl start docker

echo "Install docker-compose"
sudo curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "Install nvidia-docker"
docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f
sudo apt purge -y nvidia-docker
# Add the package repositories
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update
# Install nvidia-docker2 and reload the Docker daemon configuration
sudo apt install -y --no-install-recommends nvidia-docker2
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

echo "Configure xserver"
sudo nvidia-xconfig --enable-all-gpus --cool-bits=28 --allow-empty-initial-configuration

echo "Configure xserver-dummy service"
sudo cp ./xserver-dummy.service /etc/systemd/system/xserver-dummy.service
sudo systemctl daemon-reload
sudo systemctl enable xserver-dummy.service
sudo service xserver-dummy start

echo "Warm up nvidia-docker"
docker run --rm nvidia/cuda nvidia-smi

echo "Setup log files"
sudo mkdir -p /var/log/gpu-miner-nvidia/gominer
sudo touch /var/log/gpu-miner-nvidia/gpu-miner-nvidia.log \
    /var/log/gpu-miner-nvidia/ethminer.log \
    /var/log/gpu-miner-nvidia/ewbf.log \
    /var/log/gpu-miner-nvidia/gominer/gominer.log

echo "Install cronjobs"
crontab ${SCRIPT_DIR}/../root.crontab

echo "Install gpu-miner-nvidia service"
sudo cp ./gpu-miner-nvidia.service /etc/systemd/system/gpu-miner-nvidia.service
sudo systemctl daemon-reload
sudo systemctl enable gpu-miner-nvidia.service

echo "Setup completed! Configure .env file and reboot to start mining."

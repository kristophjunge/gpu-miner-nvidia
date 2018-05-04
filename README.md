# GPU Miner Nvidia

[![GitHub Stars](https://img.shields.io/github/stars/kristophjunge/gpu-miner-nvidia.svg?label=github%20stars)](https://github.com/kristophjunge/gpu-miner-nvidia) [![GitHub Forks](https://img.shields.io/github/forks/kristophjunge/gpu-miner-nvidia.svg?label=github%20forks)](https://github.com/kristophjunge/gpu-miner-nvidia) [![GitHub License](https://img.shields.io/github/license/kristophjunge/gpu-miner-nvidia.svg)](https://github.com/kristophjunge/gpu-miner-nvidia)

![Nvidia](https://raw.githubusercontent.com/kristophjunge/gpu-miner-nvidia/master/nvidia_logo.png)

Nvidia GPU mining setup for [Ubuntu Server](https://www.ubuntu.com/). Docker based using [nvidia-docker](https://github.com/NVIDIA/nvidia-docker). Supports ETH, ZEC and DCR mining.

Mining is causing environmental issues and will possibly not go away soon. Iam sharing this setup for easy to use energy efficient GPU mining from the software side.

**Warning: This project is experimental and can damage your hardware! Use at your own risk!**

   * [Features](#features)
   * [Changelog](#changelog)
   * [Used Containers](#used-containers)
   * [Prerequisites](#prerequisites)
   * [Installation](#installation)
   * [Manual Configuration](#manual-configuration)
      * [Overclocking](#overclocking)
   * [Usage](#usage)
   * [Logs](#logs)
   * [Limitations And Known Issues](#limitations-and-known-issues)
   * [Contributing](#contributing)
   * [License](#license)


## Features

- Based on [Ubuntu Server](https://www.ubuntu.com/) 18.04.
- Minimal x server dummy with xserver-xorg-legacy.
- Docker based with [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) and [docker-compose](https://docs.docker.com/compose/).
- Nvidia driver installation.
- [Improved version](https://github.com/ethereum-mining/ethminer) of Genoils Cuda Miner for ETH mining.
- [EWBF Miner](https://github.com/nanopool/ewbf-miner) for ZEC mining.
- [Gominer](https://github.com/decred/gominer) for DCR mining.
- Overclocking. Prepackaged with overclocking profiles for GTX1070.
- [Prometheus](https://prometheus.io/) exporters for system, GPU and mining metrics.
- CLI installation script.
- Automatic restart of crashed processes.
- Cyclic logfile clearing.
- Daily reboot or shutdown.


## Changelog

See [CHANGELOG.md](https://github.com/kristophjunge/gpu-miner-nvidia/blob/master/docs/CHANGELOG.md) for information about the latest changes.


## Used Containers

This project orchestrates the following docker containers:

- [prometheus/node-exporter](https://quay.io/repository/prometheus/node-exporter)
- [kristophjunge/ethminer-cuda](https://hub.docker.com/r/kristophjunge/ethminer-cuda/)
- [kristophjunge/ewbf](https://hub.docker.com/r/kristophjunge/ewbf/)
- [kristophjunge/decred-gominer-cuda](https://hub.docker.com/r/kristophjunge/decred-gominer-cuda/)
- [kristophjunge/prometheus-nvidiasmi](https://hub.docker.com/r/kristophjunge/prometheus-nvidiasmi/)
- [kristophjunge/prometheus-ethminer](https://hub.docker.com/r/kristophjunge/prometheus-ethminer/)
- [kristophjunge/prometheus-ewbf](https://hub.docker.com/r/kristophjunge/prometheus-ewbf/)


## Prerequisites

- Ubuntu Server 18.04
- Git


## Installation

Clone the GIT repository into the target location (Do not use other locations):
```
sudo git clone https://github.com/kristophjunge/gpu-miner-nvidia.git /opt/gpu-miner-nvidia
```

Run the setup script:
```
sudo /opt/gpu-miner-nvidia/script/setup.sh
```


## Manual Configuration

Duplicate the default configuration file:
```
sudo cp /opt/gpu-miner-nvidia/.env.default /opt/gpu-miner-nvidia/.env 
```

Configure the variables in `/opt/gpu-miner-nvidia/.env`.

Set `GPUMINERNVIDIA_NAME` to the hostname.

The variable `GPUMINERNVIDIA_MODE` controls the mode in which the miner should run. Current options are `eth`, `zec`, `dcr`. Its also possible to leave the value empty which will start only the basic monitoring containers. 


### Overclocking

Overclocking is configured by placing an `oc-profile` file in the appropriate subdirectory in the `mode` folder.

An example `oc-profile` file is located under [data/oc-profile/oc-profile-example](https://github.com/kristophjunge/gpu-miner-nvidia/blob/master/data/oc-profile/oc-profile-example).

The project is prepackaged with overclocking profiles for the GTX1070. To apply these execute the following command:

```
sudo cp -r /opt/gpu-miner-nvidia/data/oc-profile/gtx1070/* /opt/gpu-miner-nvidia/mode
```


## Usage

Start and stop the service:
```
sudo service gpu-miner-nvidia start
sudo service gpu-miner-nvidia stop
```

Enable the service for automatic startup:
```
sudo systemctl enable gpu-miner-nvidia.service
```

Reboot:
```
/opt/gpu-miner-nividia/script/reboot.sh
```

Shutdown:
```
/opt/gpu-miner-nividia/script/shutdown.sh
```


## Logs

All logs are located under `/var/log/gpu-miner-nividia`.

- The main service writes its log to `gpu-miner-nvidia.log`.
- Genoils Cuda Miner writes its log to `ethminer.log`.
- EWBF Miner writes its log to `ewbf.log`.
- Gominer writes its log to `gominer/gominer.log`.

Apart from the log files all docker containers have their own log output.


## Limitations And Known Issues

- Mining multiple coins in parallel is not possible. Not on the same GPU and also not in a split setup.
- Gominer has no Prometheus exporter. 


## Contributing

See [CONTRIBUTING.md](https://github.com/kristophjunge/gpu-miner-nvidia/blob/master/docs/CONTRIBUTING.md) for information on how to contribute to the project.

See [CONTRIBUTORS.md](https://github.com/kristophjunge/gpu-miner-nvidia/blob/master/docs/CONTRIBUTORS.md) for the list of contributors.


## License

This project is licensed under the MIT license by Kristoph Junge.

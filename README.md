# <img src='https://camo.githubusercontent.com/48b782bbddb51b97cf2971fda5817080075f7799/68747470733a2f2f7261772e6769746861636b2e636f6d2f466f7274417765736f6d652f466f6e742d417765736f6d652f6d61737465722f737667732f736f6c69642f636f67732e737667' width='50' height='50' style='vertical-align:bottom'/> Open Voice Operating System - NixOS Edition

[![AGPL-3.0-or-later](https://img.shields.io/badge/license-AGPL--v3--or--later-blue)](./LICENSE) [![ImageBuild](https://github.com/Ramblurr/ovos-rpi-nixos/actions/workflows/ImageBuild.yaml/badge.svg)](https://github.com/Ramblurr/ovos-rpi-nixos/actions)

A bootable raspberry pi image for the OpenVoice OS built and configured with NixOS. Every build is reproducible. Powered by [OpenVoiceOS/ovos-docker](https://github.com/OpenVoiceOS/ovos-docker)

* Download latest build: https://github.com/Ramblurr/ovos-rpi-nixos/releases


## Build it Yourself

Prereqs:

* docker > 20.10. You can use podman as the backend, but `docker compose` is required.

Configure:

* Edit [`config/user-config.nix`](./config/user-config.nix) and change the variables there to customize your image.

Build:

```console
$ sudo ./run.sh
# after some time your image will be in the current directory
```

Run:

* Flash the image `ovos-nix-sd-image-aarch64-linux.img` to an sd card using your favorite method
* Put it in your RPI and boot
* It will use use DHCP to connect to the network

Access:

* `ssh ovos@<IP>`

Update:
* Edit your nix configuration, you can find it in `/etc/nixos/user-config.nix`
* After editing your config, update with: `sudo nixos-rebuild switch`


## Roadmap

- [ ] Test on raspberry pi 3
- [ ] GUI Support
- [ ] User Config: network settings (Wifi SSID and password)
- [ ] User Config: mycroft.conf settings (? or delegate to [OpenVoiceOS/ovos-personal-backend](https://github.com/OpenVoiceOS/ovos-personal-backend))
- [ ] Easy-peasy update mechanism

## License

This software is licensed under the GNU AGPL v3.0 or later.

```
ovos-rpi-nixos
Copyright (C) 2023 Casey Link

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
```

The docker-based build system for the raspberry pi image  (see
[`docker/`](./docker)) is copyright 2020 Roberto Frenna under the MIT License.

## Sources

*  [NixOS Docker-based SD image builder](https://github.com/Robertof/nixos-docker-sd-image-builder/tree/master) by [Robertof](https://github.com/Robertof)

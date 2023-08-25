# <img src='https://camo.githubusercontent.com/48b782bbddb51b97cf2971fda5817080075f7799/68747470733a2f2f7261772e6769746861636b2e636f6d2f466f7274417765736f6d652f466f6e742d417765736f6d652f6d61737465722f737667732f736f6c69642f636f67732e737667' width='50' height='50' style='vertical-align:bottom'/> Open Voice Operating System - NixOS Edition

[![AGPL-3.0-or-later](https://img.shields.io/badge/license-AGPL--v3--or--later-blue)](./LICENSE) [![ImageBuild](https://github.com/Ramblurr/ovos-rpi-nixos/actions/workflows/ImageBuild.yaml/badge.svg)](https://github.com/Ramblurr/ovos-rpi-nixos/actions)

A bootable Raspberry PI image for the OpenVoice OS built and configured with
NixOS. Every build is reproducible and easily configured. Powered by
[OpenVoiceOS/ovos-docker](https://github.com/OpenVoiceOS/ovos-docker)


## Quickstart

* Download latest sd-card image: https://github.com/Ramblurr/ovos-rpi-nixos/releases
* Flash, plug in network cable, and boot
* SSH into raspberry pi (it uses DHCP)
  * user: `ovos` password: `ovos`
* Watch `systemctl status ovos-image-preload` until it says it has pulled all the container images
* `sudo podman ps` to check if all the containers are running

## Build it Yourself

While I make a [ready-to-go image
available](https://github.com/Ramblurr/ovos-rpi-nixos/releases), you should
really customize and build yourself a OVOS image that is suited to your needs.

That's where the real power of this project comes from.

### Prereqs:

* docker > 20.10
  * You can use podman as the backend (with the socket), but `docker compose` is required. If you want to do that I assume you know how to tweak your environment to make that possible

Build platforms tested:

* x86_64 Linux

### Configure:

* Copy [`config/user-config-example.nix`](./config/user-config-example.nix) to [`config/user-config.nix`](./config/user-config.nix)
* Edit it and change the variables there to customize your image.

### Build:

```console
$ sudo ./build.sh
# sudo is required when building with docker
# after some time your image will be in the current directory: ovos-nix-sd-image-aarch64-linux.img
```

Or if you run NixOS yourself, just use `nix-build.sh` to skip the docker build stuff.

### Test (optional)

Optionally test the image in a qemu VM with:

```
python scripts/test-image.py --timeout 0 ovos-nix-sd-image-aarch64-linux.img
```

Once the virtual machine boots you can ssh into it with `ssh -p 5555 ovos@localhost`

### Run:

* Flash the image `ovos-nix-sd-image-aarch64-linux.img` to an sd card using your favorite method
  * I use `sudo dd if=ovos-nix-sd-image-aarch64-linux.img of=/dev/YOUR_SD_CARD bs=64K status=progress`
* Put it in your RPI and boot
* It will use use DHCP to connect to the network

### Access:

* `ssh ovos@<IP>`
* `systemctl status ovos-image-preload`
* `systemctl status pod_ovos`
* `systemctl status ovos_messagebus`
* `systemctl status ovos_core`

Note: on the first boot all the images will have to be pulled, which can take
awhile on raspberry pi hardware. `ovos-image-preload.service` is responsible for
that.

### Update:

You want to tweak your config but don't want to build and flash an image every
time?

Well you're in luck. You can use the exact same configuration you used to build
the image to reconfigure it live.

* SSH into your OVOS device
* Edit your nix configuration, you can find it in `/etc/nixos/user-config.nix`
* After editing your config, update with: `sudo nixos-rebuild switch`
* Boom.


## Roadmap

- [x] Prebaked container images to reduce first-boot time
- [x] User Config: network settings (Wifi SSID and password)
- [ ] Test on Raspberry Pi 3
- [ ] GUI Support
- [ ] User Config: mycroft.conf settings (? or delegate to [OpenVoiceOS/ovos-personal-backend](https://github.com/OpenVoiceOS/ovos-personal-backend))
- [ ] Microphone satellites with [roc-toolkit](https://github.com/roc-streaming/roc-toolkit)
- [ ] Security
  - [ ] Remove sudo access from ovos user
  - [ ] Hivemind
- [ ] Easy-peasy update mechanism
  - [ ] Idea: A web service running on the device that exposes a web UI for updating images

## Why?

I have been running several Mycroft instances at home for awhile now. They have
always been installed and configured with some custom Ansible playbooks. Lately
I've fallen out of love with Ansible as a way to configure machines. NixOS
provides a powerful declarative method for defining what an operating system
image should look like. I've started using it on my workstations and other servers over the past year.

Recently I decided it was time to migrate from the dying (dead?) Mycroft lineage
to OpenVoiceOS (OVOS), the project picking up where Mycroft left off.

Opening my Ansible playbooks and looking at the task of refactoring them to OVOS
just filled me with dread.

As of this time (August 2023) OVOS doesn't have easily built images, users are
more or less expected to cobble together the system themselves (like with
raspbian-ovos or custom Ansible), or use Neon OS. I like the community and
hacker DIY attiude of OVOS, so I want to stick with it.

But I needed a way to reproducibly build, manage, and maintain 4 separate OVOS
instances that didn't drive me nuts.

Here we are now: OVOS running on NixOS.

Well, OVOS running in podman containers running on NixOS (because packaging all
those python modules for NixOS so they don't have to run in containers, does not
sound like fun).

Many thanks to [goldyfruit](https://github.com/goldyfruit) for his work creating
all the container definitions for
[OpenVoiceOS/ovos-docker](https://github.com/OpenVoiceOS/ovos-docker).

### Alternatives :

* [OVOS Buildroot](https://github.com/OpenVoiceOS/ovos-buildroot/issues) - An off the shelf linux distro for OVOS. Difficult to build by yourself and difficult to find recent up to date images.
* [Raspbian OVOS](https://github.com/OpenVoiceOS/raspbian-ovos/) (formerly known as picroft) - Designed to be installed ontop of a base Rasbpian install.
* [Neon AI](https://neon.ai/)

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

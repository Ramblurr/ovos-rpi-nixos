# ovos-rpi-nixos

# <img src='https://camo.githubusercontent.com/48b782bbddb51b97cf2971fda5817080075f7799/68747470733a2f2f7261772e6769746861636b2e636f6d2f466f7274417765736f6d652f466f6e742d417765736f6d652f6d61737465722f737667732f736f6c69642f636f67732e737667' width='50' height='50' style='vertical-align:bottom'/> Open Voice Operating System - NixOS Edition

A bootable raspberry pi image for the OpenVoice OS built and configured with NixOS.

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

* ssh ovos@<IP>


## Sources

*  [NixOS Docker-based SD image builder](https://github.com/Robertof/nixos-docker-sd-image-builder/tree/master) by [Robertof](https://github.com/Robertof)

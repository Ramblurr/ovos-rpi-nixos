#!/usr/bin/env sh
set -e

clear
alejandra .
echo "Syncing..."
rsync -e  "ssh -o 'ControlPath=/dev/shm/control:%h:%p:%r'" \
    -vr config/user-config.nix config/ovos config/configuration.nix ovos:/etc/nixos/
echo "Synced!"

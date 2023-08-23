#!/usr/bin/env sh
set -e

clear
if command -v "alejandra" >/dev/null 2>&1 ; then
    echo "Formatting nix files"
    alejandra .
fi
echo "Syncing..."
rsync -e  "ssh -o 'ControlPath=/dev/shm/control:%h:%p:%r'" \
    -vr config/user-config.nix config/ovos config/configuration.nix ovos:/etc/nixos/
echo "Synced!"

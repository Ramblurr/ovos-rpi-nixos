#!/usr/bin/env sh
set -e

rsync -vr config/user-config.nix config/ovos config/configuration.nix ovos@192.168.1.207:/etc/nixos/
echo "Synced!"

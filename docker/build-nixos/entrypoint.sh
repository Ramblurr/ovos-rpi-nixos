#!/usr/bin/env sh

set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}

if [ "$PUID" != "1000" ]; then
    echo "Changing nixos user $PUID:$PGID"
    /usr/sbin/groupmod -o -g "$PGID" nixos
    /usr/sbin/usermod -o -u "$PUID" nixos
    chown -R $PUID:$PGID /home/nixos
    chown -R $PUID:$PGID /nix
fi

echo "su-execing: $@"
exec /sbin/su-exec $PUID "$@"

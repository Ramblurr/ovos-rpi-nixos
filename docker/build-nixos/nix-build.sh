#!/usr/bin/env sh
# - setup the environment. This includes adding the Nix executables to $PATH, along with the
#   registration of an EXIT handler which will send a signal to `cleanup-qemu` when done.
# - wait until `setup-qemu` is done by attempting to run an AArch64 binary. This works out of
#   the box if running on AArch64.
# - build the actual SD image.
# - copy it to /build, which points by default to this directory.
. setup-env
sh wait-for-qemu.sh
set -ex
touch /build/assert-can-write-to-build-dir
rm /build/assert-can-write-to-build-dir
nix-build \
    --max-jobs $(nproc) \
    --cores 0 \
    -A config.system.build.sdImage \
    --option system aarch64-linux \
    --option sandbox false \
    -I nixos-config=/build/config/sd-image.nix \
    nixpkgs/nixos/default.nix

ls -al
ls -al /build/
ls -al result/sd-image/*

chmod u+w result/sd-image/* && sudo cp result/sd-image/* /build

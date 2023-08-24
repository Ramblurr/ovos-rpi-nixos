#!/usr/bin/env sh
# - setup the environment. This includes adding the Nix executables to $PATH, along with the
#   registration of an EXIT handler which will send a signal to `cleanup-qemu` when done.
# - wait until `setup-qemu` is done by attempting to run an AArch64 binary. This works out of
#   the box if running on AArch64.
# - build the actual SD image.
# - copy it to ${OUTPUT_DIR}, which points by default to this directory.

. setup-env
sh wait-for-qemu.sh
set -ex
OUTPUT_DIR=${OUTPUT_DIR:-/build}
touch ${OUTPUT_DIR}/assert-can-write-to-build-dir
rm ${OUTPUT_DIR}/assert-can-write-to-build-dir
nix-build \
    --max-jobs $(nproc) \
    --cores 0 \
    -A config.system.build.sdImage \
    --option system aarch64-linux \
    --option sandbox false \
    -I nixos-config=${OUTPUT_DIR}/config/sd-image.nix \
    nixpkgs/nixos/default.nix

ls -al
ls -al ${OUTPUT_DIR}/
ls -al result/sd-image/*

chmod u+w result/sd-image/* && cp result/sd-image/* ${OUTPUT_DIR}

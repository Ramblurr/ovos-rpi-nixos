#!/bin/bash
set -e
echo "waiting until QEMU container finishes..."

# this is just a binary which prints "aarch64 runs!". feel free to replace with any other binary
while ! ./aarch64-tester; do
  sleep 1
done

echo "starting build"

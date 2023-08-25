#!/usr/bin/env python3
# test-image.py
#
# Copyright (C) 2023 Casey Link
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""
Give this script a raw sd-card image file built with nix-build
and it will extract the kernel, dtb, and init path from the image
then boot a qemu virtual machine emulating a raspberry pi.
"""
import re
import argparse
import stat
import sys
import signal
import subprocess
from dataclasses import dataclass
import os
import shutil
import glob


@dataclass
class DevInfo:
    def __init__(self, device, start, sectors, offset=None):
        self.device = device
        self.start = start
        self.sectors = sectors
        self.offiset = offset


def get_devices(img):
    try:
        raw = subprocess.check_output(
            [
                "fdisk",
                "-l",
                "-o",
                "Device,Start,Sectors",
                img,
            ]
        )
    except subprocess.CalledProcessError as err:
        print(err)
        sys.exit(1)
    sectors_re = re.compile(r"Units: sectors of \d+ \* \d+ = (\d+) bytes")
    out = raw.strip().decode().split("\n")
    unit_sz = 0
    devices = []
    for l in out:
        matches = sectors_re.search(l)
        if matches and len(matches.groups()) == 1:
            unit_sz = int(matches.group(1))
        elif l.startswith(img):
            parts = l.split()
            d = DevInfo(device=parts[0], start=int(parts[1]), sectors=int(parts[2]))
            devices.append(d)
    for d in devices:
        d.offset = unit_sz * d.start

    return {
        "devices": devices,
        "img": img,
        "unit_sz": unit_sz,
    }


def report(data):
    devices = data["devices"]
    img = data["img"]
    for d in devices:
        print(
            f"{d.device} mount command:\n  mount -v -o offset={d.offset},loop {img} /mnt"
        )

    return None


# 2nd partition is where nixos puts the boot partition
def process_image(info, part_num=1):
    try:
        # Mount the second partition to /mnt/rpi
        offset = info["devices"][part_num].offset
        os.makedirs("/mnt/rpi", exist_ok=True)
        subprocess.run(
            [
                "sudo",
                "mount",
                "-v",
                "-o",
                f"offset={offset},loop",
                info["img"],
                "/mnt/rpi",
            ]
        )

        # Find the file that ends with -Image in /mnt/rpi/boot/nixos/
        image_files = glob.glob("/mnt/rpi/boot/nixos/*-Image")
        if image_files:
            image_file = image_files[0]
            print(image_file)
            shutil.copy(image_file, "kernel.img")
            os.chmod("kernel.img", stat.S_IRUSR | stat.S_IWUSR | stat.S_IRGRP)
            print(f"Copied {image_file} to kernel.img")
        else:
            print("Image file not found.")

        # Find the file named "bcm2710-rpi-3-b.dtb" deep inside /mnt/rpi/boot/nixos/
        dtb_files = glob.glob(
            "/mnt/rpi/boot/nixos/**/bcm2710-rpi-3-b.dtb", recursive=True
        )
        if dtb_files:
            dtb_file = dtb_files[0]
            shutil.copy(dtb_file, "bcm2710-rpi-3-b.dtb")
            os.chmod("bcm2710-rpi-3-b.dtb", stat.S_IRUSR | stat.S_IWUSR | stat.S_IRGRP)
            print(f"Copied {dtb_file} to bcm2710-rpi-3-b.dtb")

        else:
            print("bcm2710-rpi-3-b.dtb not found.")

        # Read and parse the extlinux.conf file
        init_path = None
        with open("/mnt/rpi/boot/extlinux/extlinux.conf", "r") as file:
            contents = file.read()
            match = re.search(r"init=(/nix/store/[-a-zA-Z0-9.-]+/init)", contents)
            if match:
                init_path = match.group(1)
                print(f"Found init path: {init_path}")
            else:
                print("init path not found.")

        return {
            "kernel": "kernel.img",
            "dtb": "bcm2710-rpi-3-b.dtb",
            "init_path": init_path,
        }

    finally:
        subprocess.run(["sudo", "umount", "/mnt/rpi"])


def convert_image(base_name: str, clean: bool):
    if clean or not os.path.isfile(f"{base_name}.qcow2"):
        print(f"Generating qcow2 image {base_name}")
        subprocess.run(
            [
                "qemu-img",
                "convert",
                "-f",
                "raw",
                "-O",
                "qcow2",
                f"{base_name}.img",
                f"{base_name}.qcow2",
            ],
            check=True,
        )
        subprocess.run(["qemu-img", "resize", f"{base_name}.qcow2", "16g"], check=True)
    return f"{base_name}.qcow2"


def run_test(image_name, devices, timeout_secs=300, clean=False, headless=False):
    base_name = os.path.splitext(image_name)[0]
    i = process_image(devices)
    kernel = i["kernel"]
    dtb = i["dtb"]
    init = i["init_path"]
    if not kernel or not dtb or not init:
        print("Error: could not find info")
        print(f"kernel: {kernel}")
        print(f"dtb: {dtb}")
        print(f"init: {init}")
        sys.exit(1)
    qcow2 = convert_image(base_name, clean)
    cmd = [
        "qemu-system-aarch64",
        "-M",
        "raspi3b",
        "-m",
        "1G",
        "-kernel",
        "kernel.img",
        "-append",
        f"console=ttyAMA0 init={init} console=ttyS0,115200n8 console=ttyAMA0,115200n8 console=tty0 cma=128M console=tty0 loglevel=7 root=/dev/mmcblk0p2 rw rootwait rootfstype=ext4 systemd.log_level=debug systemd.log_target=kmsg log_buf_len=1M printk.devkmsg=on loglevel=7 systemd.mask=swap.target systemd.mask=swapfile.swap",
        "-sd",
        qcow2,
        "-dtb",
        "bcm2710-rpi-3-b.dtb",
        "-no-reboot",
        "-device",
        "usb-net,netdev=net0",
        "-netdev",
        "user,id=net0,hostfwd=tcp::5555-:22",
    ]
    if headless:
        cmd.append("-nographic")
    else:
        cmd.append("-serial")
        cmd.append("stdio")

    def timeout_terminate(process):
        print("Timeout reached, killing vm")
        process.terminate()
        print("FAIL")
        sys.exit(1)

    if timeout_secs > 0:
        print(f"Will timeout in {timeout_secs} seconds")

    signal.signal(signal.SIGALRM, lambda signum, frame: timeout_terminate(process))

    process = subprocess.Popen(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    if timeout_secs > 0:
        signal.alarm(timeout_secs)
    if process.stdout:
        for line in iter(process.stdout.readline, ""):
            print(line.strip())
            if "Welcome to NixOS" in line:
                print("[*] System booted to login")
                process.terminate()
                break
            if "Started SSH Daemon" in line:
                print("[*] SSH Daemon booted")
            if "OVOS Image Preload" in line:
                print("[*] OVOS image preloader started !")
    if process.stderr:
        print()
        print("qemu reported the following on stderr:")
        for line in iter(process.stderr.readline, ""):
            print(line.strip())
    print("PASS")
    sys.exit(0)


def main():
    parser = argparse.ArgumentParser(description="OVOS Raspberry PI Image Tester")
    parser.add_argument("image_name", type=str, help="Image name")
    parser.add_argument(
        "--clean", action="store_true", help="If true does not used the cached image"
    )
    parser.add_argument(
        "--headless",
        action="store_true",
        help="If true will not show the virtual machine's GUI console",
    )
    # parser.add_argument(
    #    "--platform",
    #    choices=["rpi3", "rpi4"],
    #    default="rpi3",
    #    help="Platform, either rpi3 or rpi4",
    # )
    parser.add_argument(
        "--timeout", type=int, default=300, help="Timeout value in seconds"
    )

    args = parser.parse_args()

    image_name = args.image_name
    clean = args.clean
    # platform = args.platform # TODO figure out how to emulate an rpi4
    timeout = args.timeout
    headless = args.headless

    devices = get_devices(image_name)
    # report(devices)
    run_test(image_name, devices, clean=clean, timeout_secs=timeout, headless=headless)


if __name__ == "__main__":
    main()

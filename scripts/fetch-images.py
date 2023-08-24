# /usr/bin/env python3
"""# fetch-images.py ##################################################################

This script uses nix-prefetch-docker to fetch the latest container image hashes to bake
into the sdcard. This gives us reproducible builds and a full container image cache at first boot.
"""
import sys
import subprocess
import json
import re
from datetime import datetime

IMAGES = {
    # key is the docker image name (without tag)
    # value is the nix service key in config/ovos/containers.nix and config/sd-image/ovos-prebaked.nix
    "docker.io/smartgic/ovos-messagebus": "ovos_messagebus",
    "docker.io/smartgic/ovos-phal": "ovos_phal",
    "docker.io/smartgic/ovos-phal-admin": "ovos_phal_admin",
    "docker.io/smartgic/ovos-listener-dinkum": "ovos_listener",
    "docker.io/smartgic/ovos-audio": "ovos_audio",
    "docker.io/smartgic/ovos-core": "ovos_core",
    "docker.io/smartgic/ovos-cli": "ovos_cli",
}


def fetch_docker_image(image_name: str, image_tag: str, arch: str = "arm64"):
    print(f"Fetching {image_name}:{image_tag} {arch}")
    command = [
        "nix-prefetch-docker",
        "--os",
        "linux",
        "--arch",
        arch,
        "--image-name",
        image_name,
        "--image-tag",
        image_tag,
        "--final-image-tag",
        image_tag,
        "--json",
        "--quiet",
    ]
    try:
        result = subprocess.run(
            command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"An error occurred while processing")
        print(f"{image_name}: {e.stderr.decode()}")
        sys.exit(1)


def format_nix_expression(image_json, image_name):
    return f"""
imageFile = pkgs.dockerTools.pullImage {{
  imageName = "{image_name}";
  imageDigest = "{image_json['imageDigest']}";
  finalImageTag = "{image_json['finalImageTag']}";
  sha256 = "{image_json['sha256']}";
  os = "linux";
  arch = "arm64";
}};
"""


def update_nix_file(images, image_data):
    filename = "config/sd-image/ovos-prebaked.nix"

    with open(filename, "r") as file:
        content = file.read()
    for image_name, image_json in image_data.items():
        nix_key = images[image_name]
        nix_expression = format_nix_expression(image_json, image_name)
        print(image_name, nix_key)

        pattern = re.compile(
            rf"(\b{nix_key}\b\s*=\s*\{{)([\s\S]*?)(\}};)", re.MULTILINE
        )

        # Define a replacement function that only modifies the content inside the braces
        def replacement(match):
            return match.group(1) + "\n" + nix_expression

        content = pattern.sub(replacement, content)

    current_date = datetime.now().strftime("%Y-%m-%d")
    date_line = f"# LAST UPDATED: {current_date}"
    content = re.sub(r"# LAST UPDATED: \d{4}-\d{2}-\d{2}", date_line, content)

    with open(filename, "w") as file:
        file.write(content)

    subprocess.run(
        ["alejandra", filename],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )


def main():
    image_names = IMAGES.keys()
    image_tag = "alpha"
    aggregate_output = {
        image_name: fetch_docker_image(image_name, image_tag)
        for image_name in image_names
    }
    aggregate_output = {key: value for key, value in aggregate_output.items() if value}
    update_nix_file(IMAGES, aggregate_output)


# this is just here for testing the script
test_input = {
    "docker.io/smartgic/ovos-messagebus": {
        "imageName": "docker.io/smartgic/ovos-messagebus",
        "imageDigest": "sha256:76f0f0626993599ef6f018e3953ea92de585bbb22a04209fe7b2eeccdc48f5ad",
        "sha256": "032a8bb16fz75jqhn3g0zs813y2hbkafn5bmvsrngkz4wjwd3bm3",
        "finalImageName": "docker.io/smartgic/ovos-messagebus",
        "finalImageTag": "alpha",
    },
    "docker.io/smartgic/ovos-phal": {
        "imageName": "docker.io/smartgic/ovos-phal",
        "imageDigest": "sha256:a3d45347479c03835ea84c92ecbc911d14f0ad0308b04504a3dc80b55d79204e",
        "sha256": "1azak6f9a4bjjm78rcz5gm4w1myzsbgnz9g91axpl49jgw4kik27",
        "finalImageName": "docker.io/smartgic/ovos-phal",
        "finalImageTag": "alpha",
    },
    "docker.io/smartgic/ovos-phal-admin": {
        "imageName": "docker.io/smartgic/ovos-phal-admin",
        "imageDigest": "sha256:92d35b84be93799301666d9565c740ba876075f7b22d01b79a7fef188e215de9",
        "sha256": "0bda61dih1d0wsn02scniqkl6zlvn8mxvwncxfhp0mqi0vgz2z6v",
        "finalImageName": "docker.io/smartgic/ovos-phal-admin",
        "finalImageTag": "alpha",
    },
    "docker.io/smartgic/ovos-listener-dinkum": {
        "imageName": "docker.io/smartgic/ovos-listener-dinkum",
        "imageDigest": "sha256:133bc37a0c67f03bbf1d58f6345ff0b0e93528ad0be2cabedb82d3689da1169f",
        "sha256": "1g6an7ams2vpq5dpjjg8bb27hankbv69qk00m4kyyxrah47dcjhn",
        "finalImageName": "docker.io/smartgic/ovos-listener-dinkum",
        "finalImageTag": "alpha",
    },
    "docker.io/smartgic/ovos-audio": {
        "imageName": "docker.io/smartgic/ovos-audio",
        "imageDigest": "sha256:1a8eddbd47f10d5e7a2aef450c27e0f566ac474c982092872948fcf12550bab2",
        "sha256": "1wpv5bkdnhfi90frgfd1ll59nsqg0f6kxdbahhxijja448r027qj",
        "finalImageName": "docker.io/smartgic/ovos-audio",
        "finalImageTag": "alpha",
    },
    "docker.io/smartgic/ovos-core": {
        "imageName": "docker.io/smartgic/ovos-core",
        "imageDigest": "sha256:623743f7135341abd8fdd294dd9cf595a8063ca2e0d7866a22ff3d5f3081166d",
        "sha256": "07rkvk73b8x94fmy57i89chrc84yhff5617qfffbr1yylgxcg172",
        "finalImageName": "docker.io/smartgic/ovos-core",
        "finalImageTag": "alpha",
    },
    "docker.io/smartgic/ovos-cli": {
        "imageName": "docker.io/smartgic/ovos-cli",
        "imageDigest": "sha256:93fae5f8b6d23d6355e0ad13a09d84a7f16ff2d6ebd8d8318c700895f623c0ef",
        "sha256": "18wq7z97qf3j08lq5cfc713csf7ry6kx5v4xkpidvsqswrp9jjcb",
        "finalImageName": "docker.io/smartgic/ovos-cli",
        "finalImageTag": "alpha",
    },
}


def test():
    update_nix_file(IMAGES, test_input)


if __name__ == "__main__":
    # test()
    main()

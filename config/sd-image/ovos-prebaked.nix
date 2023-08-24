{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  services.ovos = {
    enable = true;
    services = {
      # LAST UPDATED: 2023-08-23
      ovos_messagebus = {
        imageFile = pkgs.dockerTools.pullImage {
          imageName = "docker.io/smartgic/ovos-messagebus";
          imageDigest = "sha256:76f0f0626993599ef6f018e3953ea92de585bbb22a04209fe7b2eeccdc48f5ad";
          finalImageTag = "alpha";
          sha256 = "032a8bb16fz75jqhn3g0zs813y2hbkafn5bmvsrngkz4wjwd3bm3";
          os = "linux";
          arch = "arm64";
        };
      };
      ovos_phal = {
        imageFile = pkgs.dockerTools.pullImage {
          imageName = "docker.io/smartgic/ovos-phal";
          imageDigest = "sha256:a3d45347479c03835ea84c92ecbc911d14f0ad0308b04504a3dc80b55d79204e";
          finalImageTag = "alpha";
          sha256 = "1azak6f9a4bjjm78rcz5gm4w1myzsbgnz9g91axpl49jgw4kik27";
          os = "linux";
          arch = "arm64";
        };
      };
      ovos_phal_admin = {
        imageFile = pkgs.dockerTools.pullImage {
          imageName = "docker.io/smartgic/ovos-phal-admin";
          imageDigest = "sha256:92d35b84be93799301666d9565c740ba876075f7b22d01b79a7fef188e215de9";
          finalImageTag = "alpha";
          sha256 = "0bda61dih1d0wsn02scniqkl6zlvn8mxvwncxfhp0mqi0vgz2z6v";
          os = "linux";
          arch = "arm64";
        };
      };
      ovos_listener = {
        imageFile = pkgs.dockerTools.pullImage {
          imageName = "docker.io/smartgic/ovos-listener-dinkum";
          imageDigest = "sha256:133bc37a0c67f03bbf1d58f6345ff0b0e93528ad0be2cabedb82d3689da1169f";
          finalImageTag = "alpha";
          sha256 = "1g6an7ams2vpq5dpjjg8bb27hankbv69qk00m4kyyxrah47dcjhn";
          os = "linux";
          arch = "arm64";
        };
      };
      ovos_audio = {
        imageFile = pkgs.dockerTools.pullImage {
          imageName = "docker.io/smartgic/ovos-audio";
          imageDigest = "sha256:1a8eddbd47f10d5e7a2aef450c27e0f566ac474c982092872948fcf12550bab2";
          finalImageTag = "alpha";
          sha256 = "1wpv5bkdnhfi90frgfd1ll59nsqg0f6kxdbahhxijja448r027qj";
          os = "linux";
          arch = "arm64";
        };
      };
      ovos_core = {
        imageFile = pkgs.dockerTools.pullImage {
          imageName = "docker.io/smartgic/ovos-core";
          imageDigest = "sha256:623743f7135341abd8fdd294dd9cf595a8063ca2e0d7866a22ff3d5f3081166d";
          finalImageTag = "alpha";
          sha256 = "07rkvk73b8x94fmy57i89chrc84yhff5617qfffbr1yylgxcg172";
          os = "linux";
          arch = "arm64";
        };
      };
      ovos_cli = {
        imageFile = pkgs.dockerTools.pullImage {
          imageName = "docker.io/smartgic/ovos-cli";
          imageDigest = "sha256:93fae5f8b6d23d6355e0ad13a09d84a7f16ff2d6ebd8d8318c700895f623c0ef";
          finalImageTag = "alpha";
          sha256 = "18wq7z97qf3j08lq5cfc713csf7ry6kx5v4xkpidvsqswrp9jjcb";
          os = "linux";
          arch = "arm64";
        };
      };
    };
  };
}

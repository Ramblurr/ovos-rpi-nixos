{
  config,
  lib,
  pkgs,
  ...
}: {
  # Set your timezone
  ovos.timezone = "Europe/Berlin";
  # Set your SSH Key to login to the pi
  ovos.sshKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzseqIeUgemCgd3/vxkcmJtpVGFS1P3ajBDYaGHHwziIUO/ENkWrEfv/33DvaaY3QQYnSMePRrsHq5ESanwEdjbMBu1quQZZWhyh/M5rQdbfwFoh2BYjCq5hFhaNUl9cjZk3xjQGHVKlTBdFfpuvWtY9wGuh1rf/0hSQauMrxAZsgXVxRhCbY+/+Yjjwm904BrWxXULbrc5yyfpgwHOHhHbpl8NIQIN6OAn3/qcVb7DlGJpLUjfolkdBTY8zGAJxEWecJzjgwwccuWdrzcWliuw0j4fu/MDOonpVQBCY9WcZeKInGHYAKu+eZ/swxAP+9vAR4mc+l/SBYyzCWvM6zG8ebbDK1mkwq2t0G183/0KSxAPJ7OykFD1a/ifb+cXNYJjshCDN+M95A3s6aMEU4VER/9SmQp3YCZvQEDKOBHlqMqlbw0IYAYE/FfU2se+gLI74JizoHBv2OJcduYdV0Ba97fvrb1lYM+tg0VmKUCwCvI9+ZbT2bJH3sM6SE9xt8+3nx6sKzV6h6FlpvDC60Rr2mANsuW3lbqac05Wnmxzk0C8OoJPCqWEmzjyWLJvPq98cG4obJiNlnp7/7xmmhOwyqcy7gDQum1QDwrUJyBKBsJPelJOZJC0pKkerv4LdSZDTSxEVxomstK/WDzmkPK9uUWTEH69VU/bUMuejTNVQ== cardno:000500006944";


  # Connect to your WLAN automatically
  # networking.wireless.networks = {
  #   "YOUR_SSID".psk = "password";
  # };

  # There are more settings see config/ovos/default.nix for more options

  # Example, to change the container images used for ovos
  # ovos.container.imageRepo = "docker.io/smartgic";
  # ovos.container.imageTag = "alpha";

  # In addition to the base ovos system,  you can install additional docker-based skills or services
  # See see config/ovos/containers.nix for more options
  # Here is an example:
  services.ovos.services = {
    ovos_skill_date_time = {
      image = "${config.ovos.container.imageRepo}/ovos-skill-date-time";
      tag = "${config.ovos.container.imageTag}";
      requires = ["ovos_core"];
    };

    # You can also override the default base images if you want
    # ovos_audio = {
    #   image = "docker.io/yourname/your-ovos-audio-image";
    #   tag = "yourtag";
    # };
  };
}

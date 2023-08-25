{
  config,
  lib,
  pkgs,
  ...
}: {
  ovos.platform = "rpi4";
  ovos.timezone = "Europe/Berlin";
  ovos.sshKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzseqIeUgemCgd3/vxkcmJtpVGFS1P3ajBDYaGHHwziIUO/ENkWrEfv/33DvaaY3QQYnSMePRrsHq5ESanwEdjbMBu1quQZZWhyh/M5rQdbfwFoh2BYjCq5hFhaNUl9cjZk3xjQGHVKlTBdFfpuvWtY9wGuh1rf/0hSQauMrxAZsgXVxRhCbY+/+Yjjwm904BrWxXULbrc5yyfpgwHOHhHbpl8NIQIN6OAn3/qcVb7DlGJpLUjfolkdBTY8zGAJxEWecJzjgwwccuWdrzcWliuw0j4fu/MDOonpVQBCY9WcZeKInGHYAKu+eZ/swxAP+9vAR4mc+l/SBYyzCWvM6zG8ebbDK1mkwq2t0G183/0KSxAPJ7OykFD1a/ifb+cXNYJjshCDN+M95A3s6aMEU4VER/9SmQp3YCZvQEDKOBHlqMqlbw0IYAYE/FfU2se+gLI74JizoHBv2OJcduYdV0Ba97fvrb1lYM+tg0VmKUCwCvI9+ZbT2bJH3sM6SE9xt8+3nx6sKzV6h6FlpvDC60Rr2mANsuW3lbqac05Wnmxzk0C8OoJPCqWEmzjyWLJvPq98cG4obJiNlnp7/7xmmhOwyqcy7gDQum1QDwrUJyBKBsJPelJOZJC0pKkerv4LdSZDTSxEVxomstK/WDzmkPK9uUWTEH69VU/bUMuejTNVQ== cardno:000500006944";
  ovos.gui.enable = false;

  # By default access is only with SSH key
  # You can enable the user password
  # (The default passsword is "ovos")
  # ovos.password.enable = true;

  # You can set your own password. It has to be a hash, you can generate one with
  # mkpasswd -m sha-512 "YOURPASSWORD" on your command line
  # WARNING: do not commit this file to git or push it to a public repo if you do that
  # ovos.password.password = "HASH";

  # Connect to your WLAN automatically
  # ovos.wireless.enable = true;
  # ovos.wireless.ssid= "YOUR SSID";
  # ovos.wireless.password = "YOUR PASSWORD";

  # To override the container images used for the default base services and
  # default skills you can change the following settings
  # ovos.container.imageRepo = "docker.io/smartgic";
  # ovos.container.imageTag = "alpha";

  services.ovos.services = {
    # Disable a default skill (see config/ovos/containers-skills.nix for the default skills)
    # skill_hello_world = {
    #   enable = false;
    # };

    # You can install your own container based skills
    # my_custom_skill = {
    #   enable = true;
    #   image = "ghcr.io/yourname/yourskill";
    #   tag = "latest";
    #   requires = ["ovos_core"];
    # };

    # You can also override the default base images if you want
    # ovos_audio = {
    #   image = "docker.io/yourname/your-ovos-audio-image";
    #   tag = "yourtag";
    # };
  };

  # There are more settings see config/ovos/default.nix for more options
}

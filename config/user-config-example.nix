{
  config,
  lib,
  pkgs,
  ...
}: {
  # Configure your settings
  ovos.platform = "rpi4";
  ovos.timezone = "Europe/Berlin";
  ovos.sshKey = "ssh-rsa ...";

  # Enable the GUI
  # WARNING: The GUI is not yet fully functional with the container based system
  ovos.gui.enable = true;

  # By default access is only with SSH key
  # You can enable the user password with this line
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

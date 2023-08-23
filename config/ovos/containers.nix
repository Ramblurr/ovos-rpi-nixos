{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [./modules/services.nix];
  services.ovos = {
    enable = true;
    services = {
      ovos_messagebus = {
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-messagebus";
        tag = mkDefault "${config.ovos.container.imageTag}";
        withConfigRO = mkDefault true;
        exposeMessageBus = mkDefault false;
      };
      ovos_phal = {
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-phal";
        tag = mkDefault "${config.ovos.container.imageTag}";
        withAudio = mkDefault true;
        requires = mkDefault ["ovos_messagebus"];
      };
      ovos_phal_admin = {
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-phal-admin";
        tag = mkDefault "${config.ovos.container.imageTag}";
        withGpioMem = mkDefault true;
        withSysDev = mkDefault true;
        withPrivileged = mkDefault true;
        requires = mkDefault ["ovos_messagebus"];
      };
      ovos_listener = {
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-listener-dinkum";
        tag = mkDefault "${config.ovos.container.imageTag}";
        withAudio = mkDefault true;
        withListenerData = mkDefault true;
        requires = mkDefault ["ovos_phal" "ovos_messagebus"];
        withConfigRO = mkDefault true;
      };
      ovos_audio = {
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-audio";
        tag = mkDefault "${config.ovos.container.imageTag}";
        withAudio = mkDefault true;
        withDBus = mkDefault true;
        requires = mkDefault ["ovos_phal" "ovos_messagebus"];
      };
      ovos_core = {
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-core";
        tag = mkDefault "${config.ovos.container.imageTag}";
        withAudio = mkDefault true;
        requires = mkDefault ["ovos_phal" "ovos_messagebus"];
        withNLTKData = mkDefault true;
        withShare = mkDefault true;
      };
      ovos_cli = {
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-cli";
        tag = mkDefault "${config.ovos.container.imageTag}";
        requires = mkDefault ["ovos_messagebus"];
      };
    };
  };
}

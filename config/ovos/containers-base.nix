{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [./modules/services.nix ./modules/gui.nix];
  services.ovos = {
    enable = true;
    services = {
      ovos_messagebus = {
        enable = true;
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-messagebus";
        tag = mkDefault "${config.ovos.container.imageTag}";
        withConfigRO = mkDefault true;
        exposeMessageBus = mkDefault false;
      };
      ovos_phal = {
        enable = true;
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-phal";
        tag = mkDefault "${config.ovos.container.imageTag}";
        withAudio = mkDefault true;
        requires = mkDefault ["ovos_messagebus"];
      };
      ovos_phal_admin = {
        enable = true;
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-phal-admin";
        tag = mkDefault "${config.ovos.container.imageTag}";
        withGpioMem = mkDefault true;
        withSysDev = mkDefault true;
        withPrivileged = mkDefault true;
        requires = mkDefault ["ovos_messagebus"];
      };
      ovos_listener = {
        enable = true;
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-listener-dinkum";
        tag = mkDefault "${config.ovos.container.imageTag}";
        withAudio = mkDefault true;
        withListenerData = mkDefault true;
        requires = mkDefault ["ovos_phal" "ovos_messagebus"];
        withConfigRO = mkDefault true;
      };
      ovos_audio = {
        enable = true;
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-audio";
        tag = mkDefault "${config.ovos.container.imageTag}";
        withAudio = mkDefault true;
        withDBus = mkDefault true;
        requires = mkDefault ["ovos_phal" "ovos_messagebus"];
      };
      ovos_core = {
        enable = true;
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-core";
        tag = mkDefault "${config.ovos.container.imageTag}";
        withAudio = mkDefault true;
        requires = mkDefault ["ovos_phal" "ovos_messagebus"];
        withNLTKData = mkDefault true;
        withShare = mkDefault true;
      };
      ovos_cli = {
        enable = true;
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-cli";
        tag = mkDefault "${config.ovos.container.imageTag}";
        requires = mkDefault ["ovos_messagebus"];
      };
      ovos_gui_websocket = mkIf config.ovos.gui.enable {
        enable = true;
        image = mkDefault "${config.ovos.container.imageRepo}/ovos-gui-websocket";
        tag = mkDefault "${config.ovos.container.imageTag}";
        requires = mkDefault ["ovos_messagebus"];
      };
      skill_wikipedia = {
        enable = true;
        image = "${config.ovos.container.imageRepo}/ovos-skill-wikipedia";
        tag = "${config.ovos.container.imageTag}";
        requires = ["ovos_core"];
      };

      skill_weather = {
        enable = true;
        image = "${config.ovos.container.imageRepo}/ovos-skill-weather";
        tag = "${config.ovos.container.imageTag}";
        requires = ["ovos_core"];
      };

      skill_volume = {
        enable = true;
        image = "${config.ovos.container.imageRepo}/ovos-skill-volume";
        tag = "${config.ovos.container.imageTag}";
        requires = ["ovos_core"];
      };

      skill_date_time = {
        enable = true;
        image = "${config.ovos.container.imageRepo}/ovos-skill-date-time";
        tag = "${config.ovos.container.imageTag}";
        requires = ["ovos_core"];
      };

      skill_stop = {
        enable = true;
        image = "${config.ovos.container.imageRepo}/ovos-skill-stop";
        tag = "${config.ovos.container.imageTag}";
        requires = ["ovos_core"];
      };

      skill_personal = {
        enable = true;
        image = "${config.ovos.container.imageRepo}/ovos-skill-personal";
        tag = "${config.ovos.container.imageTag}";
        requires = ["ovos_core"];
      };

      skill_fallback_unknown = {
        enable = true;
        image = "${config.ovos.container.imageRepo}/ovos-skill-fallback-unknown";
        tag = "${config.ovos.container.imageTag}";
        requires = ["ovos_core"];
      };

      skill_hello_world = {
        enable = true;
        image = "${config.ovos.container.imageRepo}/ovos-skill-hello-world";
        tag = "${config.ovos.container.imageTag}";
        requires = ["ovos_core"];
      };

      skill_alerts = {
        enable = true;
        image = "${config.ovos.container.imageRepo}/ovos-skill-alerts";
        tag = "${config.ovos.container.imageTag}";
        requires = ["ovos_core"];
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [./modules/services.nix ./modules/gui.nix];
  services.ovos = {
    services = {
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

{
  config,
  lib,
  pkgs,
  ...
}: {
  systemd.user.services = {
    roc-recv = lib.mkIf config.ovos.roc.recv.enable {
      enable = true;
      description = "roc-recv remote audio as input";
      script = "${pkgs.roc-toolkit}/bin/roc-recv --output pulse://default --source ${config.ovos.roc.recv.source} --control ${config.ovos.roc.recv.control} --repair ${config.ovos.roc.recv.repair} ${config.ovos.roc.recv.extraArgs}";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["default.target"];
      environment = {
        XDG_RUNTIME_DIR = "/run/user/1000";
      };
      serviceConfig = {
        Type = "simple";
      };
    };
    roc-send = lib.mkIf config.ovos.roc.send.enable {
      enable = true;
      description = "roc-send remote audio to a ovos instance";
      script = "${pkgs.roc-toolkit}/bin/roc-send --output pulse://default --input ${config.ovos.roc.send.source} --control ${config.ovos.roc.send.control} --repair ${config.ovos.roc.send.repair} ${config.ovos.roc.send.extraArgs}";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["default.target"];
      environment = {
        XDG_RUNTIME_DIR = "/run/user/1000";
      };
      serviceConfig = {
        Type = "simple";
      };
    };
  };
}

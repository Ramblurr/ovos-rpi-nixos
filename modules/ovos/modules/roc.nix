{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs;
    lib.mkIf config.ovos.roc.recv.enable [
      roc-toolkit
      openfec
    ];
  systemd.user.services = {
    roc-recv = lib.mkIf config.ovos.roc.recv.enable {
      enable = false;
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

  environment.etc."pipewire/pipewire.conf.d/101-roc-recv.conf" = lib.mkIf config.ovos.roc.recv.enable {
    text =
      builtins.toJSON
      {
        "context.modules" = [
          {
            name = "libpipewire-module-roc-source";
            args = {
              "local.ip" = "0.0.0.0";
              "resampler.profile" = "medium";
              "fec.code" = "rs8m";
              "sess.latency.msec" = 60;
              "local.source.port" = 10001;
              "local.repair.port" = 10002;
              "source.name" = "ROC Source";
              "source.props" = {
                "node.name" = "roc-recv-source";
                "node.description" = "ROC Recv Source";
                #"role" = "Speech-High";
              };
            };
          }
        ];
      };
  };
}

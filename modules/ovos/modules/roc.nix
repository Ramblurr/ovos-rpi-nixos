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
  environment.etc."pipewire/pipewire.conf.d/101-roc-recv.conf" = lib.mkIf config.ovos.roc.recv.enable {
    text =
      builtins.toJSON
      {
        "context.modules" = [
          {
            name = "libpipewire-module-roc-source";
            args = {
              "local.ip" = config.ovos.roc.recv.listenIp;
              "resampler.profile" = "medium";
              "fec.code" = "rs8m";
              "sess.latency.msec" = config.ovos.roc.recv.latencyMsec;
              "local.source.port" = config.ovos.roc.recv.sourcePort;
              "local.repair.port" = config.ovos.roc.recv.repairPort;
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

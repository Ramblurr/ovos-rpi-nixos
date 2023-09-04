{
  config,
  lib,
  pkgs,
  ...
}: {
  systemd.user.services = {
    pod_ovos = {
      path = [pkgs.podman pkgs.su];
      description = "Podman pod-pod_ovos.service";
      wants = ovosServices;
      before = ovosServices;
      after = ["network-online.target"];
      wantedBy = ["default.target"];

      unitConfig = {
        "RequiresMountsFor" = "/run/user/1000/containers";
      };
      serviceConfig = {
        Environment = "PODMAN_SYSTEMD_UNIT=%n";
        Restart = "on-failure";
        TimeoutStopSec = 70;
        ExecStartPre = ''
          ${pkgs.podman}/bin/podman pod create \
             --infra-conmon-pidfile %t/pod_ovos.pid \
             --pod-id-file %t/pod_ovos.pod-id \
             --exit-policy=stop \
             --uidmap 0:1:1000 --uidmap 1000:0:1 --uidmap 1001:1001:64536 \
             --gidmap 0:1:1000 --gidmap 1000:0:1 --gidmap 1001:1001:64536 \
             --name=pod_ovos \
             --infra=true \
             --share= \
             --replace \
        '';
        ExecStart = "${pkgs.podman}/bin/podman pod start --pod-id-file %t/pod_ovos.pod-id";
        ExecStop = "${pkgs.podman}/bin/podman pod stop --ignore  --pod-id-file %t/pod_ovos.pod-id -t 10";
        ExecStopPost = "${pkgs.podman}/bin/podman pod rm  --ignore  -f  --pod-id-file %t/pod-pod_ovos.pod-ie";
        PIDFile = "%t/pod_ovos.pid";
        Type = "forking";
      };
    };
  };
}

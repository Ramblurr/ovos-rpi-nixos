{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  ovos-shell = pkgs.writeShellScript "ovos-shell" ''
    #!/usr/bin/env bash
    set -ex
    services=("ovos_messagebus.service" "ovos_gui_websocket.service" "ovos_phal.service")

    for service in "''${services[@]}"; do
      while true; do
        if systemctl is-active --quiet "$service"; then
          echo "$service is running."
          break
        else
          echo "Waiting for $service to start..."
          sleep 1
        fi
      done
    done
    echo "All services are running."

    sudo ${pkgs.podman}/bin/podman run \
      --cidfile=%t/%n.ctr-id \
      --cgroups=no-conmon \
      --pod-id-file=%t/pod_ovos.pd-id \
      --rm \
      --sdnotify=conmon \
      --replace \
      --security-opt label=disable \
      --pull missing \
      --device /dev/dri \
      --device /dev/snd \
      --requires ovos_messagebus,ovos_gui_websocket,ovos_phal \
      -e TZ=${config.time.timeZone} \
      -e PULSE_SERVER=unix:/run/user/1000/pulse/native \
      -e XDG_SESSION_TYPE=wayland \
      -e QT_QPA_PLATFORM=wayland  \
      -e SDL_VIDEODRIVER=wayland \
      -e XDG_RUNTIME_DIR=/run/user/1000 \
      -v /home/ovos/ovos/config:/home/ovos/.config/mycroft:ro \
      -v /home/ovos/ovos/tmp:/tmp/mycroft \
      -v /run/user/1000:/run/user/1000:rw \
      -v /run/user/1000/pulse:/run/user/1000/pulse:ro \
      -v /home/ovos/ovos/share:/home/ovos/.local/share/mycroft \
      --name=ovos_gui \
      --label ovos.service=ovos_gui \
      docker.io/smartgic/ovos-gui:alpha
  '';
in {
  config = mkIf config.ovos.gui.enable {
    services.xserver.enable = true;
    hardware.opengl.enable = true;
    services.cage = {
      enable = true;
      user = "ovos";
      program = ovos-shell;
    };
  };
}

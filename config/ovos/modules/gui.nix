{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  ovos-shell = pkgs.writeShellScript "ovos-shell" ''
    #!/bin/bash
    set -ex
    ${pkgs.podman}/bin/podman run \
      --cidfile=%t/%n.ctr-id \
      --cgroups=no-conmon \
      --userns=keep-id:uid=1000,gid=1000 \
      --rm \
      --sdnotify=conmon \
      --replace \
      --security-opt label=disable \
      --pull missing \
      --device /dev/dri \
      --device /dev/snd \
      -e TZ=${config.ovos.timezone} \
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

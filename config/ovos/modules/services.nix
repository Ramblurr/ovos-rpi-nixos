{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.ovos;

  shouldConcat = option:
    if isList option
    then option != []
    else option;
  ovosConfig = "/home/ovos/ovos/config";
  ovosData = "/home/ovos/ovos/data";
  ovosTmp = "/home/ovos/ovos/tmp";
  hivemindConfig = "/home/ovos/hivemind/config";
  hivemindShare = "/home/ovos/hivemind/share";
  ovosShare = "/home/ovos/ovos/share";
  xdgRuntimeDir = "/run/user/1000";
  pullPolicy = "missing";
  pulseServer = "unix:/run/user/1000/pulse/native";
  #pulseCookie = "/home/ovos/.config/pulse/cookie";
  PodIdFile = "%t/pod_ovos.pd-id";
  commonOpts = ''
    ${pkgs.podman}/bin/podman run \
      --cidfile=%t/%n.ctr-id \
      --cgroups=no-conmon \
      --user 1000:1000 \
      --rm \
      --pod-id-file ${PodIdFile} \
      --sdnotify=conmon \
      --replace \
      --detach \
      --log-driver=journald \
      --security-opt label=disable \
      --pull ${pullPolicy} \
      -e TZ=${config.ovos.timezone} \
      -v ${ovosTmp}:/tmp/mycroft \
  '';
  #--network host \
  #
  imageInfoList = map (service: {
    imageNameAndTag = "${service.image}:${service.tag}";
    imageFile = service.imageFile;
  }) (attrValues cfg.services);
  concatenatedImageNamesAndTags = concatStringsSep "" (map (info: info.imageNameAndTag) imageInfoList);
  hashOfServices = builtins.hashString "sha256" concatenatedImageNamesAndTags;

  commonServiceConfig = name: opts: {
    description = "Podman container ${name} service";
    wants = ["network-online.target" "ovos-image-preload.service"];
    after = ["network-online.target" "ovos-image-preload.service"] ++ map (name: "${name}.service") opts.requires;
    bindsTo = map (name: "${name}.service") opts.requires;
    enable = true;
    unitConfig = {
      RequiresMountsFor = "%t/containers";
    };
    serviceConfig = {
      Environment = "PODMAN_SYSTEMD_UNIT=%n";
      Restart = "on-failure";
      TimeoutStopSec = 70;
      TimeoutStartSec = "infinity";
      RestartSec = 5;
      ExecStart =
        commonOpts
        + " --name=${name}  --label ovos.service=${name} "
        + concatStringsSep " " (
          map (item:
            if shouldConcat item.o
            then item.v
            else "")
          [
            {
              o = true;
              v = "-v ${ovosConfig}:/home/ovos/.config/mycroft${
                if opts.withConfigRO
                then ":ro"
                else ""
              }";
            }
            {
              o = opts.withAudio;
              v = ''
                --device /dev/snd \
                -e PULSE_SERVER=${pulseServer} \
                -v ${xdgRuntimeDir}/pulse:${xdgRuntimeDir}/pulse:ro'';
            }
            #-e PULSE_COOKIE=${pulseCookie} \
            #-v ${pulseCookie}:${pulseCookie}:ro \
            {
              o = opts.withDBus;
              v = "-e DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus --volume /run/user/1000/bus:/run/user/1000/bus:ro";
            }
            {
              o = opts.withPrivileged;
              v = "--privileged";
            }
            {
              o = opts.withShare;
              v = "--volume ${ovosShare}:/home/ovos/.local/share/mycroft";
            }
            {
              o = opts.withSysDev;
              v = "--volume /dev:/dev --volume /sys:/sys";
            }
            {
              o = opts.withGpioMem;
              v = "--device /dev/gpiomem --group-add 997";
            }
            {
              o = opts.devices;
              v = concatMapStringsSep " " (device: "--device ${device}") opts.devices;
            }
            {
              o = opts.requires;
              v = "--requires " + concatStringsSep "," opts.requires;
            }
            {
              o = opts.withNLTKData;
              v = concatMapStringsSep " " (v: "--volume ${ovosData}/${v}") [
                "ovos_nltk:/home/ovos/nltk_data"
              ];
            }
            {
              o = opts.withListenerData;
              v = concatMapStringsSep " " (v: "--volume ${ovosData}/${v}") [
                "ovos_listener_records:/home/ovos/.local/share/mycroft/listener"
                "ovos_models:/home/ovos/.local/share/precise-lite"
                "ovos_vosk:/home/ovos/.local/share/vosk"
              ];
            }
            {
              o = opts.exposeMessageBus;
              v = "--publish 127.0.0.1:8181:8181";
            }
          ]
        )
        + " ${opts.image}:${opts.tag}";
      ExecStop = "${pkgs.podman}/bin/podman stop --ignore -t 10 --cidfile=%t/%n.ctr-id";
      ExecStopPost = "${pkgs.podman}/bin/podman rm -f --ignore -t 10 --cidfile=%t/%n.ctr-id";
      Type = "notify";
      NotifyAccess = "all";
    };
  };
in {
  options.services.ovos = {
    enable = mkEnableOption "Enable Podman services";
    services = mkOption {
      type = types.attrsOf (types.submodule ({name, ...}: {
        options = {
          image = mkOption {
            type = types.str;
            description = "Container image for the service";
          };
          tag = mkOption {
            type = types.str;
            description = "Tag for the container image";
          };
          imageFile = mkOption {
            type = with types; nullOr package;
            default = null;
            description = mdDoc ''
              Path to an image file to load before running the image. This can
              be used to bypass pulling the image from the registry.

              The `image` attribute must match the name and
              tag of the image contained in this file, as they will be used to
              run the container with that image. If they do not match, the
              image will be pulled from the registry as usual.
            '';
            example = literalExpression "pkgs.dockerTools.buildImage {...};";
          };
          withAudio = mkOption {
            type = types.bool;
            default = false;
            description = "Attach audio resources";
          };
          withGpioMem = mkOption {
            type = types.bool;
            default = false;
            description = "Mount /dev/gpiomem";
          };
          withDBus = mkOption {
            type = types.bool;
            default = false;
            description = "Attach DBUS resources";
          };
          withSysDev = mkOption {
            type = types.bool;
            default = false;
            description = "Mount /dev and /sys";
          };
          withPrivileged = mkOption {
            type = types.bool;
            default = false;
            description = "add --privileged";
          };
          withListenerData = mkOption {
            type = types.bool;
            default = false;
            description = "Add mounts for listener data";
          };
          withNLTKData = mkOption {
            type = types.bool;
            default = false;
            description = "Add mounts for NLTK data";
          };
          withShare = mkOption {
            type = types.bool;
            default = false;
            description = "Add XDG share mount";
          };
          withConfigRO = mkOption {
            type = types.bool;
            default = false;
            description = "Whether or not the config mount should be read-only";
          };
          exposeMessageBus = mkOption {
            type = types.bool;
            default = false;
            description = "Whether or not to expose the message bus to the host";
          };
          requires = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Services that this one requires";
          };
          devices = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Devices to attach";
          };
        };
      }));
    };
    default = {};
    description = "OVOS container services";
  };

  config = mkIf cfg.enable {
    system.activationScripts.createOVOSDirs = {
      text = ''
        mkdir -p /home/ovos/ovos/{config/apps,share/skills,share/intent_cache,config/skills,tmp} \
          /home/ovos/ovos/tmp \
          /home/ovos/ovos/data/{ovos_nltk,ovos_vosk,ovos_listener_records,ovos_models} \
          /home/ovos/hivemind/{config,share}
        chown -R ovos:ovos /home/ovos/ovos
      '';
    };
    systemd.services =
      {
        ovos-image-preload = {
          description = "OVOS Image Preload";
          script =
            ''
              echo "OVOS Image Preload Starting"
            ''
            + concatStringsSep "\n" (map (
                info:
                  if info.imageFile != null
                  then ''
                    set +e
                    if ! ${pkgs.podman}/bin/podman image exists "${info.imageNameAndTag}"; then
                      #${pkgs.podman}/bin/podman load -i "${info.imageFile}"
                      ${pkgs.podman}/bin/podman pull "${info.imageNameAndTag}"
                    fi
                    set -e
                  ''
                  else ""
              )
              imageInfoList)
            + ''
              touch /etc/ovos-image-load-complete-${hashOfServices}
              echo "OVOS Image Preload Complete"
            '';
          wants = ["network-online.target"];
          after = ["network-online.target"];
          wantedBy = ["default.target"];
          serviceConfig = {
            Restart = "no";
            KillMode = "process";
            Type = "oneshot";
            RemainAfterExit = "yes";
            TimeoutStartSec = "60min";
          };
        };
        pod_ovos = let
          serviceNames = attrNames cfg.services;
          systemdUnitNames = map (name: "${name}.service") serviceNames;
        in {
          path = [pkgs.podman pkgs.su];
          description = "OVOS Podman Pod";
          before = systemdUnitNames;
          wants = systemdUnitNames ++ ["ovos-image-preload.service"];
          after = ["network-online.target" "ovos-image-preload.service"];
          wantedBy = ["default.target"];
          unitConfig = {
            RequiresMountsFor = "/run/user/1000/containers";
          };
          serviceConfig = {
            Environment = "PODMAN_SYSTEMD_UNIT=%n";
            Restart = "no";
            TimeoutStopSec = 70;
            ExecStartPre = ''
              ${pkgs.podman}/bin/podman pod create \
                 --infra-conmon-pidfile %t/pod_ovos.pid \
                 --pod-id-file ${PodIdFile} \
                 --exit-policy=stop \
                 --userns=keep-id:uid=1000,gid=1000 \
                 --name=pod_ovos \
                 --infra=true \
                 --replace
            '';
            #--uidmap 0:1:1000 --uidmap 1000:0:1 \
            #--gidmap 0:1:1000 --gidmap 1000:0:1 \
            ExecStart = "${pkgs.podman}/bin/podman pod start --pod-id-file ${PodIdFile}";
            ExecStop = "${pkgs.podman}/bin/podman pod stop --ignore  --pod-id-file ${PodIdFile} -t 10";
            ExecStopPost = "${pkgs.podman}/bin/podman pod rm  --ignore  -f  --pod-id-file ${PodIdFile}";
            PIDFile = "%t/pod_ovos.pid";
            Type = "forking";
          };
        };
      }
      // mapAttrs' (name: opts: nameValuePair "${name}" (commonServiceConfig name opts)) cfg.services;
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  security.rtkit.enable = false;
  hardware.pulseaudio.enable = pkgs.lib.mkForce false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = false; # ?
    pulse.enable = true;
    jack.enable = false;
    wireplumber.enable = true;
    audio.enable = true;
    package = pkgs.pipewire.override {libcameraSupport = false;};
  };

  systemd.user.services = {
    pipewire.wantedBy = ["default.target"];
    wireplumber.wantedBy = ["default.target"];
    pipewire-pulse = {
      wantedBy = ["default.target"];
    };
  };
  environment.etc."pipewire/pipewire.conf.d/100-user.conf" = {
    text =
      builtins.toJSON
      {
        "context.modules" = [
          {
            name = "libpipewire-module-rt";
            args = {
              "nice.level" = 20;
              "rt.prio" = 88;
              "rtportal.enabled" = false;
              "rtkit.enabled" = false;
              "rlimits.enabled" = true;
            };
            flags = ["ifexists" "nofail"];
          }
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.name" = "music-to-speakers-bridge";
              "node.description" = "music-to-speakers-bridge";
              "target.delay.sec" = 0;
              "capture.props" = {
                "node.target" = "alsa_input.platform-soc_sound.stereo-fallback";
              };
              "playback.props" = {
                "monitor.channel-volumes" = true;
                "media.role" = "Multimedia";
                #"device.intended-roles" = "Multimedia";
              };
            };
          }
          #{name = "libpipewire-module-protocol-native";}
          #{name = "libpipewire-module-profiler";}
          #{name = "libpipewire-module-spa-device-factory";}
          #{name = "libpipewire-module-spa-node-factory";}
          ## Config to make pipewire discover stuff around it with zeroconf.
          #{name = "libpipewire-module-link-factory";}
          #{name = "libpipewire-module-session-manager";}
          #{name = "libpipewire-module-zeroconf-discover";}
          #{name = "libpipewire-module-raop-discover";}
        ];
      };
  };
  #environment.etc."wireplumber/main.lua.d/51-disable-builtin-rpi-audio.lua".text = ''
  #  rule = {
  #    matches = {
  #      {
  #        { "node.name", "equals", "alsa_output.platform-bcm2835_audio.stereo-fallback" },
  #      },
  #    },
  #    apply_properties = {
  #      ["device.disabled"] = true,
  #      ["node.description"] = "snd_rpi_builtin"
  #    },
  #  }

  #  table.insert(alsa_monitor.rules,rule)
  #'';

  #environment.etc."wireplumber/main.lua.d/51-rename-devices.lua".text = ''
  #  rule = {
  #    matches = {
  #      {
  #        { "node.name", "equals", "alsa_output.platform-soc_sound.stereo-fallback" },

  #      },
  #    },
  #    apply_properties = {
  #        ["node.description"] = "snd_rpi_hifiberry_dacplus_sink"
  #    },
  #  }

  #  table.insert(alsa_monitor.rules,rule)
  #  rule2 = {
  #    matches = {
  #      {
  #        { "node.name", "equals", "alsa_input.platform-soc_sound.stereo-fallback" },

  #      },
  #    },
  #    apply_properties = {
  #        ["node.description"] = "snd_rpi_hifiberry_dacplus_source"
  #    },
  #  }

  #  table.insert(alsa_monitor.rules,rule2)
  #'';
  environment.etc."wireplumber/policy.lua.d/50-endpoints-config.lua".text = ''
    default_policy.policy.roles = {
      ["Capture"] = {
        ["alias"] = {  "Capture" },
        ["priority"] = 25,
        ["action.default"] = "cork",
        ["action.capture"] = "mix",
        ["media.class"] = "Audio/Source",
      },
      ["Multimedia"] = {
        ["alias"] = { "Movie", "Music", "Game" },
        ["priority"] = 25,
        ["action.default"] = "mix",
      },
      ["Speech"] = {
        ["priority"] = 60,
        ["action.default"] = "duck",
        ["action.Speech"] = "mix",
      }
    }

    default_policy.endpoints = {
      ["endpoint.capture"] = {
        ["media.class"] = "Audio/Source",
        ["role"] = "Capture",
      },
      ["endpoint.multimedia"] = {
        ["media.class"] = "Audio/Sink",
        ["role"] = "Multimedia",
      },
      ["endpoint.speech"] = {
        ["media.class"] = "Audio/Sink",
        ["role"] = "Speech",
      },
    }
  '';
}
# pw-link  "alsa_input.platform-soc_sound.stereo-fallback:capture_FL" "control.endpoint.multimedia:playback_FL"
# pw-link "alsa_input.platform-soc_sound.stereo-fallback:capture_FR" "control.endpoint.multimedia:playback_FR"
# pw-link "roc-recv-source:receive_FR" "control.endpoint.speech_high:playback_FR"
# pw-link "roc-recv-source:receive_FL" "control.endpoint.speech_high:playback_FL"

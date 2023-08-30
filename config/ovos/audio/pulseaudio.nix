{
  config,
  lib,
  pkgs,
  ...
}: {
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.support32Bit = false;

  environment.systemPackages = with pkgs; [
    pulsemixer
  ];

  # pacmd update-sink-proplist alsa_output.platform-soc_sound.stereo-fallback  device.description="snd_rpi_hifiberry_dacplus"
  # pacmd update-sink-proplist alsa_output.platform-bcm2835_audio.stereo-fallback  device.description="snd_rpi_builtin"
}

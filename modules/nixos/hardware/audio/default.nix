{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.hardware.audio;
in {
  options.hardware.audio = with types; {
    enable = mkBoolOpt false "Enable or disable hardware audio support";
  };

  config = mkIf cfg.enable {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
      jack.enable = true;
    };
    programs.noisetorch.enable = true;

    services.udev.packages = with pkgs; [
      headsetcontrol
    ];

    environment.systemPackages = with pkgs; [
      headsetcontrol
      headset-charge-indicator
      pulsemixer
    ];
  };
}

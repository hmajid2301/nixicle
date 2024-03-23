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
    enable = mkBoolOpt false "Enable or disable pipewire";
  };

  config = mkIf cfg.enable {
    # Enable sound with pipewire.
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
    programs.noisetorch.enable = true;

    services.udev.packages = with pkgs; [
      # headsetcontrol2
    ];

    # TODO: add headset as a package
    environment.systemPackages = with pkgs; [
      # headsetcontrol2
      headset-charge-indicator
      pulsemixer
    ];
  };
}

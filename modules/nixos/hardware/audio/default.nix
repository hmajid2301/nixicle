{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.hardware.audio;
in
{
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

      extraConfig.pipewire."99-usb-audio-fix" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 512;
          "default.clock.min-quantum" = 64;
          "default.clock.max-quantum" = 4096;
        };
      };

      wireplumber.configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/99-usb-audio.conf" ''
          monitor.alsa.rules = [
            {
              matches = [
                {
                  device.name = "~alsa_card.usb-ACTIONS_Pebble.*"
                }
              ]
              actions = {
                update-props = {
                  api.alsa.period-size = 256
                  api.alsa.periods = 4
                  api.alsa.headroom = 2048
                  api.alsa.disable-batch = true
                  session.suspend-timeout-seconds = 0
                  api.alsa.start-delay = 0
                  api.alsa.disable-tsched = false
                  api.acp.auto-profile = false
                  device.profile = "output:analog-stereo"
                }
              }
            }
          ]
        '')
      ];
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

{
  config,
  pkgs,
  lib,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;

let
  cfg = config.hardware.audio;
in
{
  options.hardware.audio = with types; {
    enable = mkBoolOpt false "Enable or disable hardware audio support";
  };

  config = mkIf cfg.enable {
    security.rtkit.enable = true;
    services = {
      pulseaudio.enable = false;
      pipewire = {
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
                    api.acp.auto-port = false
                    device.profile = "output:analog-stereo"
                    device.intended-roles = "Music"
                  }
                }
              }
            ]
          '')
          (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/99-disable-pro-audio.conf" ''
            monitor.alsa.rules = [
              {
                matches = [
                  {
                    device.name = "~alsa_card.usb-ACTIONS_Pebble.*"
                  }
                ]
                actions = {
                  update-props = {
                    device.profile.pro-audio = false
                  }
                }
              }
            ]
          '')
          (pkgs.writeTextDir "share/wireplumber/policy.conf.d/99-pebble-policy.conf" ''
            alsa_monitor.properties = {
              alsa.reserve = false
            }

            default.clock.allowed-rates = [ 44100 48000 88200 96000 ]

            # Pebble device policy
            device.policy = {
              roles = {
                Multimedia = {
                  matches = [
                    {
                      device.name = "~alsa_card.usb-ACTIONS_Pebble.*"
                    }
                  ]
                  default.audio.rate = 48000
                  default.audio.channels = 2
                  default.audio.format = "S16LE"
                  api.acp.pro-audio.disabled = true
                }
              }
            }
          '')
        ];
      };

      udev.packages = with pkgs; [
        headsetcontrol
      ];
    };

    programs.noisetorch.enable = true;

    environment.systemPackages = with pkgs; [
      headsetcontrol
      headset-charge-indicator
      pulsemixer
    ];

    # Create script to restore Pebble profile on connection
    systemd.user.services.pebble-profile-manager = {
      description = "Manage Pebble V3 audio profile";
      wantedBy = [ "pipewire.service" ];
      after = [ "pipewire.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart =
          let
            script = pkgs.writeShellScript "pebble-profile-fix" ''
              # Wait for audio system to be ready
              sleep 2

              # Find Pebble card
              PEBBLE_CARD=$(${pkgs.pulseaudio}/bin/pactl list cards short | grep -i "pebble" | cut -f2)

              if [ -n "$PEBBLE_CARD" ]; then
                echo "Found Pebble card: $PEBBLE_CARD"
                # Force set to analog stereo profile
                ${pkgs.pulseaudio}/bin/pactl set-card-profile "$PEBBLE_CARD" output:analog-stereo
                echo "Set Pebble to analog stereo profile"
              else
                echo "No Pebble card found"
              fi
            '';
          in
          "${script}";
      };
    };

    # Udev rule to trigger profile fix when Pebble is connected
    services.udev.extraRules = ''
      SUBSYSTEM=="sound", ATTR{id}=="V3", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="pebble-profile-manager.service"
      SUBSYSTEM=="usb", ATTR{idVendor}=="041e", ATTR{idProduct}=="3272", ACTION=="add", RUN+="${pkgs.systemd}/bin/systemctl --user restart pebble-profile-manager.service"
    '';
  };
}

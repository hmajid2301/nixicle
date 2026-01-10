{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.jellyfin;
in
{
  options.services.nixicle.jellyfin = {
    enable = mkEnableOption "Enable jellyfin service";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          libva-vdpau-driver
          libvdpau-va-gl
          rocmPackages.clr.icd
        ];
      };

      users.users.jellyfin.extraGroups = [
        "render"
        "video"
        "media"
      ];

      services = {
        jellyfin = {
          enable = true;
          openFirewall = true;

          hardwareAcceleration = {
            enable = true;
            type = "vaapi";
            device = "/dev/dri/renderD128";
          };

          transcoding = {
            throttleTranscoding = false;
            threadCount = 0;
            enableHardwareEncoding = true;
            enableToneMapping = true;
            enableSubtitleExtraction = true;
            h264Crf = 23;
            h265Crf = 28;

            hardwareDecodingCodecs = {
              h264 = true;
              hevc = true;
              hevc10bit = true;
              av1 = true;
              vp9 = true;
              vp8 = true;
              mpeg2 = true;
              vc1 = true;
            };

            hardwareEncodingCodecs = {
              hevc = true;
            };
          };
        };
      };
    }
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "jellyfin";
        port = 8096;
      };
    }
  ]);
}

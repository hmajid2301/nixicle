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
      nixpkgs.overlays = [
        (final: prev: {
          vaapiIntel = prev.vaapiIntel.override { enableHybridCodec = true; };
        })
      ];

      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-vaapi-driver # previously vaapiIntel
          libva-vdpau-driver
          intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
          vpl-gpu-rt # QSV on 11th gen or newer
        ];
      };

      services = {
        jellyfin.enable = true;
        jellyfin.openFirewall = true;
      };
    }

    # Traefik reverse proxy configuration
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "jellyfin";
        port = 8096;
      };
    }
  ]);
}

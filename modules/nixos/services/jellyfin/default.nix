{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nixicle.jellyfin;
in {
  options.services.nixicle.jellyfin = {
    enable = mkEnableOption "Enable jellyfin service";
  };

  config = mkIf cfg.enable {
    nixpkgs.config.packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
    };

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver # previously vaapiIntel
        vaapiVdpau
        intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
        vpl-gpu-rt # QSV on 11th gen or newer
        intel-media-sdk # QSV up to 11th gen
      ];
    };

    services = {
      jellyfin.enable = true;

      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              jellyfin.loadBalancer.servers = [
                {
                  url = "http://localhost:8096";
                }
              ];
            };

            routers = {
              jellyfin-vps = {
                entryPoints = ["websecure"];
                rule = "Host(`jellyfin.haseebmajid.dev`)";
                service = "jellyfin";
                tls.certResolver = "letsencrypt";
              };

              jellyfin = {
                entryPoints = ["websecure"];
                rule = "Host(`jellyfin.homelab.haseebmajid.dev`)";
                service = "jellyfin";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
    };
  };
}

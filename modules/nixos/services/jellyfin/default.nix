{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.jellyfin;
in {
  options.services.nixicle.jellyfin = {
    enable = mkEnableOption "Enable The jellyfin service";
  };

  config = mkIf cfg.enable {
    services = {
      jellyfin = {
        enable = true;
        openFirewall = true;
        user = config.user.name;
      };
      jellyseerr = {
        enable = true;
      };
    };
    environment.systemPackages = [
      pkgs.jellyfin
      pkgs.jellyfin-web
      pkgs.jellyfin-ffmpeg
    ];
  };
}

{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.audiobookshelf;
in {
  options.services.nixicle.audiobookshelf = {
    enable = mkEnableOption "Enable the audiobookshelf service";
  };

  config = mkIf cfg.enable {
    services.audiobookshelf = {
      enable = true;
      port = 8555;
      group = "media";
    };

    services.cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
      ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
        "audiobookshelf.haseebmajid.dev" = "http://localhost:8555";
      };
    };
  };
}

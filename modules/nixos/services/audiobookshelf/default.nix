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
    services = {
      audiobookshelf = {
        enable = true;
        port = 8555;
        group = "media";
      };

      cloudflared = {
        enable = true;
        tunnels = {
          "ec0b6af0-a823-4616-a08b-b871fd2c7f58" = {
            ingress = {
              "audiobookshelf.haseebmajid.dev" = "http://localhost:8555";
            };
          };
        };
      };
    };
  };
}

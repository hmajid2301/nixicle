{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.navidrome;
in {
  options.services.nixicle.navidrome = {
    enable = mkEnableOption "Enable the navidrome service";
  };

  config = mkIf cfg.enable {
    services = {
      navidrome = {
        enable = true;
        group = "media";
        settings = {MusicFolder = "/mnt/share/media/Music";};
      };

      cloudflared = {
        enable = true;
        tunnels = {
          "ec0b6af0-a823-4616-a08b-b871fd2c7f58" = {
            ingress = {
              "navidrome.haseebmajid.dev" = "http://localhost:4533";
            };
          };
        };
      };
    };
  };
}

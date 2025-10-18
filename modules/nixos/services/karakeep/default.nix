{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nixicle.karakeep;
in {
  options.services.nixicle.karakeep = {
    enable = mkEnableOption "Enable the karakeep service";
  };

  config = mkIf cfg.enable {
    systemd.services.karakeep = {
      description = "Karakeep - Self-hostable bookmark-everything app";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        ExecStart = "${pkgs.karakeep}/bin/karakeep";
        Restart = "always";
        RestartSec = "10s";
        User = "karakeep";
        Group = "karakeep";
        WorkingDirectory = "/var/lib/karakeep";
        StateDirectory = "karakeep";
        Environment = [
          "KARAKEEP_HOST=127.0.0.1"
          "KARAKEEP_PORT=3030"
        ];
      };
    };

    users = {
      users.karakeep = {
        isSystemUser = true;
        group = "karakeep";
        home = "/var/lib/karakeep";
        createHome = true;
      };
      groups.karakeep = {};
    };

    services = {
      cloudflared = {
        enable = true;
        tunnels = {
          "ec0b6af0-a823-4616-a08b-b871fd2c7f58" = {
            ingress = {
              "karakeep.haseebmajid.dev" = "http://localhost:3030";
            };
          };
        };
      };
    };
  };
}
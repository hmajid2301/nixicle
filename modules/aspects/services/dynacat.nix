_: {
  den.aspects.dynacat = {
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.nixicle.dynacat;
        settingsFormat = pkgs.formats.yaml { };
      in
      {
        options.nixicle.dynacat = {
          enable = lib.mkEnableOption "Dynacat dashboard";
          port = lib.mkOption {
            type = lib.types.port;
            default = 8092;
            description = "Port for the Dynacat web UI.";
          };
          environmentFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to an environment file for \${ENV_VAR} substitution in settings.";
          };
          settings = lib.mkOption {
            inherit (settingsFormat) type;
            default = { };
            description = "Dynacat configuration (https://github.com/Panonim/dynacat).";
          };
        };

        config = lib.mkIf cfg.enable {
          users.users.dynacat = {
            isSystemUser = true;
            group = "dynacat";
          };
          users.groups.dynacat = { };

          systemd.services.dynacat = {
            description = "Dynacat dashboard server";
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            serviceConfig = {
              ExecStart = "${lib.getExe pkgs.nixicle.dynacat} --config ${
                settingsFormat.generate "dynacat.yml" (
                  {
                    server = {
                      host = "127.0.0.1";
                      inherit (cfg) port;
                    };
                  }
                  // cfg.settings
                )
              }";
              EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
              Restart = "on-failure";
              User = "dynacat";
              Group = "dynacat";
              StateDirectory = "dynacat";
              StateDirectoryMode = "0700";
              CacheDirectory = "dynacat";
              RuntimeDirectory = "dynacat";
              RuntimeDirectoryMode = "0755";
              ProtectHome = true;
              ProtectSystem = "strict";
              PrivateTmp = true;
              NoNewPrivileges = true;
              UMask = "0077";
            };
          };

          services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
            name = "dynacat";
            inherit (cfg) port;
            domain = config.nixicle.domains.root;
          };
        };
      };
  };
}

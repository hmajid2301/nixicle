{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.gitlab-runner;
in
{
  options.services.nixicle.gitlab-runner = {
    enable = mkEnableOption "Enable gitlab runner";
    sopsFile = mkOption {
      type = types.path;
      default = ../secrets.yaml;
      description = "SOPS secrets file path";
    };
  };

  config = mkIf cfg.enable {
    # IP forwarding enabled by Docker module
    virtualisation.docker = {
      enable = true;
      liveRestore = false;
    };

    services.gitlab-runner = {
      enable = true;
      settings = {
        concurrent = 10;
      };
      services = {
        default = {
          authenticationTokenConfigFile = cfg.sopsFile;
          limit = 10;
          dockerImage = "debian:stable";
          dockerPrivileged = true;
          dockerVolumes = [
            "/cache"
            "/certs/client"
          ];
          environmentVariables = {
            DOCKER_TLS_CERTDIR = "/certs";
          };
        };
      };
    };

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          {
            directory = "/var/lib/private/gitlab-runner";
            user = "gitlab-runner";
            group = "gitlab-runner";
            mode = "0750";
            defaultPerms.mode = "0700";
          }
        ];
      };
    };
  };
}

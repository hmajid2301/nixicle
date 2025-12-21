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
      liveRestore = false; # Required for Docker Swarm mode
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
            # "/nix/store:/nix/store:ro"
            # "/nix/var/nix/db:/nix/var/nix/db:ro"
            # "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
          ];
        };
      };
    };

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          { directory = "/var/lib/private/gitlab-runner"; user = "gitlab-runner"; group = "gitlab-runner"; mode = "0750"; defaultPerms.mode = "0700"; }
          { directory = "/var/lib/docker"; user = "root"; group = "root"; mode = "0710"; }
        ];
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.gitlab-runner;
in
{
  options.services.nixicle.gitlab-runner = {
    enable = mkEnableOption "Enable gitlab runner";
  };

  config = mkIf cfg.enable {
    sops.secrets.gitlab_runner_env = {
      sopsFile = ../secrets.yaml;
    };

    boot.kernel.sysctl."net.ipv4.ip_forward" = true;
    virtualisation.docker.enable = true;
    services.gitlab-runner = {
      enable = true;
      settings = {
        concurrent = 10;
      };
      services = {
        default = {
          authenticationTokenConfigFile = config.sops.secrets.gitlab_runner_env.path;
          limit = 10;
          dockerImage = "debian:stable";
          dockerPrivileged = true;
          dockerVolumes = [
            "/cache"
            "/nix/store:/nix/store:ro"
            "/nix/var/nix/db:/nix/var/nix/db:ro"
            "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
          ];
        };
      };
    };
  };
}

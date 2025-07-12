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
    sopsFile = mkOption {
      type = types.path;
      default = ../secrets.yaml;
      description = "SOPS secrets file path";
    };
  };

  config = mkIf cfg.enable {
    boot.kernel.sysctl."net.ipv4.ip_forward" = true;
    virtualisation.docker.enable = true;

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
  };
}

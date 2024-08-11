{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nixicle.gitlab-runner;
in {
  options.services.nixicle.gitlab-runner = {
    enable = mkEnableOption "Enable gitlab runner";
  };

  config = mkIf cfg.enable {
    sops.secrets.gitlab_runner_env = {
      sopsFile = ../secrets.yaml;
    };

    boot.kernel.sysctl."net.ipv4.ip_forward" = true;
    services.gitlab-runner = {
      enable = true;
      settings = {
        concurrent = 10;
      };
      services = {
        # runner for building in docker via host's nix-daemon
        # nix store will be readable in runner, might be insecure
        # nix = {
        #   authenticationTokenConfigFile = config.sops.secrets.gitlab_runner_env.path;
        #   dockerImage = "alpine";
        #   dockerVolumes = [
        #     "/nix/store:/nix/store:ro"
        #     "/nix/var/nix/db:/nix/var/nix/db:ro"
        #     "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
        #   ];
        #   dockerDisableCache = true;
        #   preBuildScript = pkgs.writeScript "setup-container" ''
        #     mkdir -p -m 0755 /nix/var/log/nix/drvs
        #     mkdir -p -m 0755 /nix/var/nix/gcroots
        #     mkdir -p -m 0755 /nix/var/nix/profiles
        #     mkdir -p -m 0755 /nix/var/nix/temproots
        #     mkdir -p -m 0755 /nix/var/nix/userpool
        #     mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
        #     mkdir -p -m 1777 /nix/var/nix/profiles/per-user
        #     mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
        #     mkdir -p -m 0700 "$HOME/.nix-defexpr"
        #
        #     . ${pkgs.nix}/etc/profile.d/nix.sh
        #
        #     ${pkgs.nix}/bin/nix-env -i ${concatStringsSep " " (with pkgs; [nix cacert git openssh])}
        #
        #     ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixpkgs-unstable
        #     ${pkgs.nix}/bin/nix-channel --update nixpkgs
        #   '';
        #   environmentVariables = {
        #     ENV = "/etc/profile";
        #     USER = "root";
        #     NIX_REMOTE = "daemon";
        #     PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
        #     NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
        #   };
        # };
        # runner for building docker images
        # docker-images = {
        #   authenticationTokenConfigFile = config.sops.secrets.gitlab_runner_env.path;
        #   limit = 10;
        #
        #   dockerImage = "docker:stable";
        #   dockerVolumes = [
        #     "/var/run/docker.sock:/var/run/docker.sock"
        #   ];
        # };
        # runner for everything else
        default = {
          authenticationTokenConfigFile = config.sops.secrets.gitlab_runner_env.path;
          limit = 10;
          dockerImage = "debian:stable";
        };
      };
    };
  };
}

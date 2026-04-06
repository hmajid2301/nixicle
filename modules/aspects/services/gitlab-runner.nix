{ den, lib, ... }:
{
  den.aspects.gitlab-runner = {
    includes = [ (import ./_persist-forwarder.nix { inherit den lib; }) ];
    persist.directories = [
          { directory = "/var/lib/private/gitlab-runner"; user = "gitlab-runner"; group = "gitlab-runner"; mode = "0750"; defaultPerms.mode = "0700"; }
        ];
    nixos = { config, lib, ... }: {
      virtualisation.docker = {
        enable = true;
        liveRestore = false;
      };

      services.gitlab-runner = {
        enable = true;
        settings.concurrent = 10;
        services.default = {
          authenticationTokenConfigFile = config.sops.secrets.gitlab_runner_env.path;
          limit = 10;
          dockerImage = "debian:stable";
          dockerPrivileged = true;
          dockerVolumes = [ "/cache" "/certs/client" ];
          environmentVariables.DOCKER_TLS_CERTDIR = "/certs";
        };
      };

    };
  };
}

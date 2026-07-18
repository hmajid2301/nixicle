{ den, ... }:
{
  den.aspects.gitlab-runner = {
    includes = [ den.aspects.docker ];
    persist.directories = [
      {
        # DynamicUser services store StateDirectory under /var/lib/private; no
        # stable gitlab-runner user exists during impermanence activation.
        directory = "/var/lib/private/gitlab-runner";
        user = "root";
        group = "root";
        mode = "0750";
      }
    ];
    nixos =
      { config, ... }:
      {
        virtualisation.docker = {
          enable = true;
          liveRestore = false;
        };

        services.gitlab-runner = {
          enable = true;
          settings = {
            concurrent = 10;
            check_interval = 3;
          };
          services.default = {
            authenticationTokenConfigFile = config.sops.secrets.gitlab_runner_env.path;
            limit = 10;
            requestConcurrency = 4;
            dockerImage = "debian:stable";
            dockerPrivileged = true;
            dockerVolumes = [
              "/cache"
              "/certs/client"
            ];
            environmentVariables.DOCKER_TLS_CERTDIR = "/certs";
          };
        };

      };
  };
}

{ lib, ... }:
{
  den.aspects.podman = {
    persist.directories = [ "/var/lib/containers" ];

    nixos = _: {
      virtualisation = {
        containers.enable = true;
        podman = {
          enable = true;
          # Docker-socket emulation is opt-in: it conflicts with
          # virtualisation.docker (only one can own /var/run/docker.sock), so
          # default off and let hosts that want the shim turn it on.
          dockerSocket.enable = lib.mkDefault false;
          dockerCompat = lib.mkDefault false;
          defaultNetwork.settings.dns_enabled = true;
        };
      };

      networking.firewall.enable = true;
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
    };

    homeManager =
      { config, lib, ... }:
      {
        home.sessionVariables =
          lib.mkIf (config.osConfig.virtualisation.podman.dockerSocket.enable or false)
            {
              DOCKER_HOST = "unix://%XDG_RUNTIME_DIR%/podman/podman.sock";
            };
      };
  };
}

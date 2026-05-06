{ den, lib, ... }:
{
  den.aspects.podman = {
    persist.directories = [ "/var/lib/containers" ];

    nixos =
      { config, ... }:
      {
        virtualisation = {
          containers.enable = true;
          podman = {
            enable = true;
            dockerSocket.enable = lib.mkDefault true;
            dockerCompat = lib.mkDefault true;
            defaultNetwork.settings.dns_enabled = true;
          };
        };

        networking.firewall.enable = true;
        boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      };

    homeManager = _: {
      home.sessionVariables = {
        DOCKER_HOST = "unix://%XDG_RUNTIME_DIR%/podman/podman.sock";
      };
    };
  };
}

{ ... }:
{
  den.aspects.docker = {
    persist.directories = [
      {
        directory = "/var/lib/docker";
        user = "root";
        group = "root";
        mode = "0755";
      }
    ];

    nixos =
      { pkgs, ... }:
      {
        virtualisation = {
          docker = {
            enable = true;
            enableOnBoot = true;
            autoPrune.enable = true;
            storageDriver = "btrfs";
            daemon.settings = {
              default-address-pools = [
                {
                  base = "172.16.0.0/12";
                  size = 24;
                }
              ];
            };
            rootless = {
              enable = true;
              setSocketVariable = true;
              daemon.settings = {
                default-address-pools = [
                  {
                    base = "172.16.0.0/12";
                    size = 24;
                  }
                ];
              };
            };
          };
          oci-containers.backend = "docker";
        };

        networking.firewall.trustedInterfaces = [
          "docker0"
          "docker_gwbridge"
        ];

        environment.systemPackages = with pkgs; [
          docker-compose
        ];
      };
  };
}

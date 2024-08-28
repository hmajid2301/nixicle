{
  pkgs,
  lib,
  ...
}: {
  security = {
    sops.enable = true;
  };

  services = {
    ssh.enable = true;

    nixicle = {
      tailscale.enable = true;
      traefik.enable = true;
    };
  };

  topology.self = {
    hardware.info = "flyvps";
  };

  system.stateVersion = "23.11";
}

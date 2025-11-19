{delib, ...}:
delib.host {
  name = "s100";
  rice = "catppuccin";

  myconfig = {
    hosts.s100 = {
      type = "server";
      isServer = true;
      system = "x86_64-linux";
    };
  };

  nixos = {pkgs, lib, myconfig, ...}: lib.mkIf (myconfig.host.name == "s100") {
    imports = [
      ./hardware-configuration.nix
      ./disks.nix.helper
    ];

    roles = {
      server.enable = true;
    };

    services.nixicle = {
      traefik.enable = true;
      postgresql.enable = true;
      home-assistant.enable = true;
      adguard.enable = true;
      n8n.enable = true;
      logging.enable = true;
      otel-collector.enable = true;
    };

    topology.self = {
      hardware.info = "S100";
    };

    boot = {
      supportedFilesystems = lib.mkForce ["btrfs"];
      kernelPackages = pkgs.linuxPackages_latest;
      resumeDevice = "/dev/disk/by-label/nixos";
    };

    system.stateVersion = "23.11";
  };
}

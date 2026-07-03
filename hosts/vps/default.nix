{ den, ... }:
{
  den.aspects.vps = {
    includes = [
      den.aspects.performance-base
      den.aspects.server
      den.aspects.tailscale
      den.aspects.traefik
      den.aspects.uptime-kuma
      den.aspects.postgresql
      den.aspects.redis
      den.aspects.banterbus
    ];

    nixos =
      { lib, ... }:
      {
        imports = [
          ./hardware-configuration.nix
          ./disks.nix
        ];

        boot = {
          loader.systemd-boot.enable = lib.mkForce false;
          loader.grub.enable = lib.mkDefault true;
          initrd.systemd.enable = lib.mkForce false;
        };

        services.dbus.implementation = "dbus";

        sops.defaultSopsFile = ./secrets.yaml;
        sops.age.sshKeyPaths = lib.mkForce [ "/etc/ssh/ssh_host_ed25519_key" ];

        users.users.nixos = {
          isNormalUser = true;
          group = "users";
          extraGroups = [ "wheel" ];
          initialPassword = "changeme";
        };

        time.timeZone = lib.mkForce "UTC";

        security.sudo = {
          wheelNeedsPassword = false;
          execWheelOnly = true;
        };

        services.openssh.ports = [ 22 ];

        networking = {
          hostName = "vps";
          useDHCP = lib.mkDefault true;
          interfaces.ens3.useDHCP = lib.mkDefault true;
        };

        system.stateVersion = "24.05";
      };
  };
}

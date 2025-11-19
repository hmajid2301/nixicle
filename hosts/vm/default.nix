{delib, ...}:
delib.host {
  name = "vm";
  rice = "catppuccin";

  myconfig = {
    hosts.vm = {
      type = "desktop";
      isDesktop = true;
      system = "x86_64-linux";
    };
  };

  nixos = {pkgs, lib, myconfig, ...}: lib.mkIf (myconfig.host.name == "vm") {
    imports = [
      ./hardware-configuration.nix
      ./disks.nix.helper
    ];

    networking.hostName = "vm";
    system.boot.plymouth = lib.mkForce false;

    system.impermanence.enable = true;

    services.ssh.enable = true;

    # Enable QEMU guest agent for better VM integration
    services.qemuGuest.enable = true;

    # Enable SPICE vdagent for clipboard sharing between host and guest
    services.spice-vdagentd.enable = true;

    # Allow passwordless sudo for wheel group (needed for deploy-rs)
    security.sudo.wheelNeedsPassword = false;

    roles = {
      desktop.enable = true;
      desktop.addons.gnome.enable = true;
    };

    boot = {
      supportedFilesystems = lib.mkForce [ "btrfs" ];
      kernelPackages = pkgs.linuxPackages_latest;
      resumeDevice = "/dev/disk/by-label/nixos";
    };

    system.stateVersion = "23.11";
  };

  home = {lib, myconfig, ...}: lib.mkIf (myconfig.host.name == "vm") {
    roles = {
      desktop.enable = true;
      gaming.enable = true;
    };

    nixicle.user = {
      enable = true;
      name = "haseeb";
    };

    # Disable keychain for VM to avoid SSH key errors on fresh installs
    cli.tools.ssh.enableKeychain = false;

    home.stateVersion = "23.11";
  };
}

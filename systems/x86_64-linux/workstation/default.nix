{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    inputs.nixos-facter-modules.nixosModules.facter
    { config.facter.reportPath = ./facter.json; }
  ];

  environment.pathsToLink = [ "/share/fish" ];

  environment.systemPackages = with pkgs; [
    inputs.caelestia.packages.${pkgs.system}.default
    inputs.caelestia.inputs.caelestia-cli.packages.${pkgs.system}.default
    cifs-utils
    samba
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.kdeconnect.enable = true;
  system.boot.plymouth = lib.mkForce false;

  # TODO: when merged in: https://github.com/systemd/systemd/issues/34304
  systemd.package = pkgs.systemd.overrideAttrs (old: {
    patches = old.patches ++ [
      (pkgs.fetchurl {
        url = "https://github.com/wrvsrx/systemd/compare/tag_fix-hibernate-resume%5E...tag_fix-hibernate-resume.patch";
        hash = "sha256-Z784xysVUOYXCoTYJDRb3ppGiR8CgwY5CNV8jJSLOXU=";
      })
    ];
  });

  hardware.nixicle.ddcci.enable = true;

  users.users.haseeb.extraGroups = [ "i2c" ];

  services = {
    virtualisation.kvm.enable = true;
    virtualisation.docker.enable = true;
    # TODO: Look into enabling podman again in the future
    virtualisation.podman.enable = lib.mkForce false;
    hardware.openrgb.enable = true;
  };

  roles = {
    gaming.enable = true;
    desktop = {
      enable = true;
      addons = {
        hyprland.enable = true;
        gnome.enable = true;
      };
    };
  };

  programs.wireshark.enable = true;

  # Thunar file manager with thumbnail support
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
      thunar-media-tags-plugin
    ];
  };
  
  # Required for Thunar preferences in non-XFCE environments
  programs.xfconf.enable = true;
  
  # Thumbnail support and mount functionality
  services.tumbler.enable = true;
  services.gvfs.enable = true;

  # Explicitly disable systemd-networkd to avoid infinite recursion
  networking.useNetworkd = lib.mkForce false;
  systemd.network.enable = lib.mkForce false;

  # SMB/CIFS mount
  fileSystems."/mnt/videos" = {
    device = "//[2a0a:ef40:1065:4f01:7a55:36ff:fe01:15ae]/main";
    fsType = "cifs";
    options = [
      "credentials=/etc/samba/credentials"
      "vers=3.0"
      "iocharset=utf8"
      "uid=1000"
      "gid=100"
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
    ];
  };

  boot = {
    kernelParams = [ "resume_offset=533760" ];
    blacklistedKernelModules = [
      "ath12k_pci"
      "ath12k"
    ];

    supportedFilesystems = lib.mkForce [ "btrfs" "cifs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  system.stateVersion = "23.11";
}

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
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.kdeconnect.enable = true;
  system.boot.plymouth = lib.mkForce false;

  # TODO: when merged in
  systemd.package = pkgs.systemd.overrideAttrs (old: {
    patches = old.patches ++ [
      (pkgs.fetchurl {
        url = "https://github.com/wrvsrx/systemd/compare/tag_fix-hibernate-resume%5E...tag_fix-hibernate-resume.patch";
        hash = "sha256-Z784xysVUOYXCoTYJDRb3ppGiR8CgwY5CNV8jJSLOXU=";
      })
    ];
  });

  services = {
    virtualisation.kvm.enable = true;
    hardware.openrgb.enable = true;
    nixicle.nfs.enable = true;
    # nixicle.ollama.enable = true;
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
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  boot = {
    kernelParams = [ "resume_offset=533760" ];
    blacklistedKernelModules = [
      "ath12k_pci"
      "ath12k"
    ];

    supportedFilesystems = lib.mkForce [ "btrfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";

    initrd = {
      supportedFilesystems = [ "nfs" ];
      kernelModules = [ "nfs" ];
    };
  };

  system.stateVersion = "23.11";
}

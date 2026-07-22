{
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/profiles/installation-device.nix"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.wireless.enable = lib.mkForce false;
  networking.useDHCP = lib.mkForce false;
  networking.networkmanager.enable = lib.mkForce false;

  systemd.network.enable = true;
  systemd.network.networks."20-recovery-static" = {
    matchConfig.Name = [ "en*" "eth*" ];
    DHCP = "no";
    address = [ "192.168.50.2/24" ];
    networkConfig = {
      LinkLocalAddressing = "no";
      IPv6AcceptRA = false;
      IPv6PrivacyExtensions = "no";
    };
  };

  services = {
    xserver.enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  i18n.defaultLocale = "en_GB.UTF-8";
  time.timeZone = "Europe/London";

  nix.enable = true;

  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  services.openssh.enable = true;

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "8425e349";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLrECFz5PQ5D2+QXomsLK9HcZhHzcBUIDGkiI94c6Ux hello@haseebmajid.dev"
  ];

  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLrECFz5PQ5D2+QXomsLK9HcZhHzcBUIDGkiI94c6Ux hello@haseebmajid.dev"
  ];

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    gparted
    git
    vim
    htop
    curl
    wget
    zfs
    smartmontools
    nvme-cli
    pciutils
    lshw
    tmux
    zellij
    ethtool
    usbutils
    nixos-facter
  ];

  system.stateVersion = "23.11";
}

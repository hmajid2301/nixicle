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

  roles = {
    desktop.addons.gnome.enable = true;
  };

  nix.enable = true;

  system = {
    locale.enable = true;
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  services.openssh.enable = true;

  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
  ];

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    gparted
    git
    vim
    htop
    curl
    wget
  ];

  system.stateVersion = "23.11";
}

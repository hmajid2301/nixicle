{
  lib,
  pkgs,
  config,
  ...
}: {
  # Boot configuration for ISO
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # Network configuration
  networking.wireless.enable = lib.mkForce false;
  networking.networkmanager.enable = true;

  # Enable SSH using our custom SSH module
  services.ssh.enable = true;

  # Basic locale setup for ISO
  i18n.defaultLocale = "en_US.UTF-8";

  # Auto-login for convenience
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  # User configuration - only for ISO builds
  users.users = lib.mkIf false {
    nixos = {
      isNormalUser = true;
      group = "nixos";
      extraGroups = ["networkmanager"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
      ];
    };
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
    ];
  };

  users.groups = lib.mkIf false {
    nixos = {};
  };

  # Essential packages for the live ISO
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    wget
    curl
    firefox
  ];

  system.stateVersion = "24.05";
}
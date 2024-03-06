{
  pkgs,
  inputs,
  outputs,
  lib,
  ...
}: {
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      inputs.disko.nixosModules.disko
      inputs.lanzaboote.nixosModules.lanzaboote

      ./auto-upgrade.nix
      ./locale.nix
      ./nix.nix
      ./hardware.nix
      ./fonts.nix
      ./openssh.nix
      ./opengl.nix
      ./pam.nix
      ./sops.nix

      ./optional/avahi.nix
      ./optional/auto-hibernate.nix
      ./optional/backup.nix
      ./optional/bluetooth.nix
      ./optional/docker.nix
      ./optional/hardening.nix
      ./optional/fingerprint.nix
      ./optional/greetd.nix
      ./optional/gaming.nix
      ./optional/power.nix
      ./optional/virtualisation.nix
      ./optional/vpn.nix
    ]
    ++ (builtins.attrValues outputs.nixosModules);

  home-manager.extraSpecialArgs = {inherit inputs outputs;};
  networking.networkmanager.enable = true;
  programs.hyprland.enable = true;

  services = {
    pcscd.enable = true;
    udev.packages = with pkgs; [yubikey-personalization];
    gvfs.enable = true;
    udisks2.enable = true;
    fwupd.enable = true;
    dbus.packages = [pkgs.gcr];
  };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  sound.enable = true;
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = lib.mkForce false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
}

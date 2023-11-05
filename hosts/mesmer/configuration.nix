{ pkgs, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix

    ../../nixos/global
    ../../nixos/users/haseeb.nix

    ../../nixos/optional/auto-upgrade.nix
    ../../nixos/optional/avahi.nix
    ../../nixos/optional/greetd.nix
    ../../nixos/optional/quietboot.nix
    ../../nixos/optional/docker.nix
    ../../nixos/optional/fonts.nix
    ../../nixos/optional/vpn.nix
    ../../nixos/optional/pipewire.nix
    ../../nixos/optional/vfio.nix
    ../../nixos/optional/gaming.nix
    ../../nixos/optional/tailscale.nix

    ../../nixos/optional/backup.nix
    #../nixos/optional/grub.nix
  ];

  environment.systemPackages = [
    pkgs.headsetcontrol2
    pkgs.headset-charge-indicator
  ];
  services.udev.packages = [ pkgs.headsetcontrol2 ];

  networking = {
    hostName = "mesmer";
  };

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.luks.devices = {
      root = {
        device = "/dev/disk/by-uuid/0c07218e-5df9-4312-b0da-06b5881c1236";
        preLVM = true;
      };
    };
    resumeDevice = "/dev/disk/by-label/swap";
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}

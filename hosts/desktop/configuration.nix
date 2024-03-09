{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disks.nix

    ../../nixos
    ../../nixos/users/haseeb.nix
  ];

  networking = {
    hostName = "desktop";
  };

  modules.nixos = {
    avahi.enable = true;
    auto-hibernate.enable = false;
    backup.enable = true;
    bluetooth.enable = true;
    docker.enable = true;
    gaming.enable = true;
    login.enable = true;
    extraSecurity.enable = true;
    power.enable = true;
    virtualisation.enable = true;
    vpn.enable = true;
  };

  environment.systemPackages = with pkgs; [
    headsetcontrol2
    headset-charge-indicator
  ];

  swapDevices = [{device = "/swap/swapfile";}];

  environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ]);

  boot = {
    kernelParams = [
      "resume_offset=533760"
    ];
    supportedFilesystems = lib.mkForce ["btrfs"];
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    resumeDevice = "/dev/disk/by-label/nixos";
    # lanzaboote = {
    #   enable = true;
    #   pkiBundle = "/etc/secureboot";
    # };
  };

  # boot.plymouth = {
  #   enable = true;
  #   themePackages = [(pkgs.catppuccin-plymouth.override {variant = "mocha";})];
  #   theme = "catppuccin-mocha";
  # };
  boot.initrd.systemd.enable = true;

  system.stateVersion = "23.11";
}

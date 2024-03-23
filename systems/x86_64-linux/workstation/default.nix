{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  suites = {
    gaming.enable = true;
    desktop = {
      enable = true;
      addons = {
        gnome.enable = true;
        hyprland.enable = true;
      };
    };
  };

  networking.hostName = "workstation";

  virtualisation.kvm = {
    vfio = {
      enable = true;
      IOMMUType = "amd";
      devices = ["10de:2208" "10de:1aef"];
      blacklistNvidia = true;
      sharedMemoryFiles = {
        # scream = {
        #   user = "haseeb";
        #   group = "qemu-libvirtd";
        #   mode = "666";
        # };
        looking-glass = {
          user = "haseeb";
          group = "haseeb";
          mode = "666";
        };
      };
      hugepages = {
        enable = true;
        defaultPageSize = "1G";
        pageSize = "1G";
        numPages = 16;
      };
    };
    libvirtd = {
      clearEmulationCapabilities = false;
      deviceACL = [
        "/dev/input/by-id/usb-Logitech_USB_Receiver-event-mouse"
        "/dev/input/by-id/usb-ZSA_Technology_Labs_Voyager-event-kbd"
        "/dev/vfio/vfio"
        "/dev/vfio/2"
        "/dev/vfio/6"
        "dev/null"
        "/dev/full"
        "/dev/zero"
        "/dev/random"
        "/dev/urandom"
        "/dev/ptmx"
        "/dev/kvm"
        "/dev/kqemu"
        "/dev/rtc"
        "/dev/hpet"
        "/dev/kvm"
        "/dev/shm/looking-glass"
      ];
    };
  };

  swapDevices = [{device = "/swap/swapfile";}];

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

    initrd.systemd.enable = true;
  };

  system.stateVersion = "23.11";
}

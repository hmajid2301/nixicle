{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
 let
  cfg = config.hardware.raspberry-pi-5;
in {
  options.hardware.raspberry-pi-5 = {
    enable = mkEnableOption "Enable The raspberry-pi-5 config";
  };

  config = mkIf cfg.enable {
    boot = {
      kernelPackages = (import <nixpkgs-rpi5> {}).linuxPackages_rpi5;
      kernelParams = [
        "cgroup_memory=1"
        "cgroup_enable=cpuset"
        "cgroup_enable=memory"
      ];
      supportedFilesystems = ["btrfs"];

      initrd.kernelModules = ["zstd" "btrfs"];
      initrd.availableKernelModules = [
        # Allows early (earlier) modesetting for the Raspberry Pi
        "vc4"
        "bcm2835_dma"
        "i2c_bcm2835"
        "uas"
        "pcie-brcmstb"
        "reset-raspberrypi"

        # Maybe needed for SSD boot?
        "usb_storage"
        "xhci_pci"
        "usbhid"
        "uas"
      ];
    };

    hardware.enableRedistributableFirmware = true;
  };
}

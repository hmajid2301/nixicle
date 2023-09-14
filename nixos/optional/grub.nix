{ pkgs
, inputs
, ...
}: {
  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        enable = true;
        efiSupport = true;
        useOSProber = true;
        theme = inputs.grub-theme + "/src/catppuccin-mocha-grub-theme";
        enableCryptodisk = true;
        device = "/dev/nvme0n1";
      };
    };
    initrd.luks.devices = {
      root = {
        device = "/dev/disk/by-label/luks";
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };
}

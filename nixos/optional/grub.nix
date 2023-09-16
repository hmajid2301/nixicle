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
        theme = inputs.grub-theme + "/src/catppuccin-mocha-grub-theme";
        device = "nodev";
      };
    };
    initrd.luks.devices = {
      cryptroot = {
        device = "/dev/nvme0n1p3";
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };
}

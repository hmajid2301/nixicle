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
    kernelPackages = pkgs.linuxPackages_latest;
  };
}

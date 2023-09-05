{ pkgs
, inputs
, ...
}: {
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    useOSProber = true;
    theme = inputs.grub-theme + "/src/catppuccin-frappe-grub-theme";
    enableCryptodisk = true;
    device = "nodev";
  };
}

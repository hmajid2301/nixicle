{
  imports = [
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "vm";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    useOSProber = true;
  };

  suites = {
    desktop.enable = true;
    desktop.addons.gnome.enable = true;
  };

  system.stateVersion = "23.11";
}

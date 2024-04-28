{lib, ...}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.wireless.enable = lib.mkForce false;
  networking.networkmanager.enable = true;

  nix.enable = true;
  services = {
    openssh.enable = true;
  };

  system = {
    fonts.enable = true;
    locale.enable = true;
  };

  user = {
    name = "haseeb";
    initialPassword = "1";
  };

  system.stateVersion = "23.11";
}

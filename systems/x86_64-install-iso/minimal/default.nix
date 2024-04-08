{lib, ...}: {
  # `install-iso` adds wireless support that
  # is incompatible with networkmanager.
  networking.wireless.enable = lib.mkForce false;

  nix.enable = true;
  hardware = {
    networking.enable = true;
  };

  services = {
    openssh.enable = true;
  };

  system = {
    boot.enable = true;
    fonts.enable = true;
    locale.enable = true;
  };

  system.stateVersion = "23.11";
}

{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.hardware.nixicle.ddcci;
in
{
  options.hardware.nixicle.ddcci = {
    enable = mkEnableOption "Enable DDC/CI support for monitor control";
  };

  config = mkIf cfg.enable {
    # Enable i2c-dev kernel module for DDC/CI communication
    boot.kernelModules = [ "i2c-dev" ];

    # Install ddcutil system-wide
    environment.systemPackages = with pkgs; [ ddcutil ];

    # Add user to i2c group for hardware access
    users.groups.i2c = { };

    # Create udev rules for i2c devices
    services.udev.extraRules = ''
      # Allow users in i2c group to access i2c devices
      KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
    '';

    # Add users who need DDC/CI access to the i2c group
    # This needs to be configured per-user in their system configuration
  };
}


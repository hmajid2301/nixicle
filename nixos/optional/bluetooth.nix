{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.nixos.bluetooth;
in {
  options.modules.nixos.bluetooth = {
    enable = mkEnableOption "Enable bluetooth service and packages";
  };

  config = mkIf cfg.enable {
    services.blueman.enable = true;
    hardware.bluetooth.powerOnBoot = false;
    hardware.bluetooth.enable = true;
    hardware.bluetooth.settings = {
      General = {
        Experimental = true;
      };
    };
  };
}

{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.cockpit;
in {
  options.services.nixicle.cockpit = {
    enable = mkEnableOption "Enable cockpit";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      packagekit
    ];
    services.cockpit = {
      enable = true;
      openFirewall = true;
    };
  };
}

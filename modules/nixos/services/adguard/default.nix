{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.adguard;
in {
  options.services.nixicle.adguard = {
    enable = mkEnableOption "Enable AdGuard Home";
  };

  config = mkIf cfg.enable {
    services.adguardhome = {
      enable = true;
      openFirewall = true;
    };
  };
}

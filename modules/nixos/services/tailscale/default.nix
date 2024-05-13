{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.tailscale;
in {
  options.services.nixicle.tailscale = {
    enable = mkEnableOption "Enable tailscale";
  };

  config = mkIf cfg.enable {
    services.tailscale.enable = true;
  };
}

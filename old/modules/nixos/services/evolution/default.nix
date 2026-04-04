{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.evolution;
in
{
  options.services.nixicle.evolution = with types; {
    enable = mkBoolOpt false "Enable evolution-data-server for calendar/contacts";
  };

  config = mkIf cfg.enable {
    services.gnome.evolution-data-server.enable = true;

    environment.systemPackages = with pkgs; [
      gnome-online-accounts
      python3
    ];

    programs.dconf.enable = true;
  };
}

{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  inherit (config) my colorscheme;
  inherit (my.settings) host;
  inherit (colorscheme) colors;
  cfg = config.modules.shells.nushell;
in {
  options.modules.shells.nushell = {
    enable = mkEnableOption "enable nushell shell";
  };

  config = mkIf cfg.enable {
    programs.nushell = {
      enable = true;
    };
  };
}

{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.tuis;
in {
  options.programs.tuis = {
    enable = mkEnableOption "Enable TUI applications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      s-tui
    ];
  };
}

{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.modules.shells.zsh;
in {
  options.modules.shells.zsh = {
    enable = mkEnableOption "enable zsh configuration";
  };

  config = mkIf cfg.enable {
    programs.zsh = mkIf cfg.enable {
      enable = true;
    };
  };
}

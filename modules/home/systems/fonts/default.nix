{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.system.fonts;
in {
  options.system.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to manage fonts";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
    ];

    fonts.fontconfig.enable = lib.mkForce true;
  };
}

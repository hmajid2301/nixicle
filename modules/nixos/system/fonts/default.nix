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
    enable = mkBoolOpt false "Whether or not to manage fonts.";
    fonts = mkOpt (listOf package) [] "Custom font packages to install.";
  };

  config = mkIf cfg.enable {
    fonts = {
      enableDefaultPackages = false;
      fontDir.enable = true;
      packages = with pkgs;
        [
          (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
        ]
        ++ cfg.fonts;
    };
  };
}

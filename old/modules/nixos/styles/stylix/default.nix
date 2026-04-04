{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.styles.stylix;
in
{
  options.styles.stylix = {
    enable = lib.mkEnableOption "Enable stylix";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      enableDefaultPackages = true;
      fontDir.enable = true;
      fontconfig = {
        enable = true;
        useEmbeddedBitmaps = true;

        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <!-- Add Symbols Nerd Font as a global fallback -->
            <match target="pattern">
              <test name="family" compare="not_eq">
                <string>Symbols Nerd Font</string>
              </test>
              <edit name="family" mode="append">
                <string>Symbols Nerd Font</string>
              </edit>
            </match>
          </fontconfig>
        '';
      };
    };

    stylix = {
      enable = true;
      autoEnable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      homeManagerIntegration.autoImport = false;
      homeManagerIntegration.followSystem = false;
    };
  };
}

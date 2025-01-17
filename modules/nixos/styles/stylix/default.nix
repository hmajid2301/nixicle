{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.styles.stylix;
in {
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
          <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
          <fontconfig>
              <alias binding="weak">
                  <family>monospace</family>
                  <prefer>
                      <family>emoji</family>
                  </prefer>
              </alias>
              <alias binding="weak">
                  <family>sans-serif</family>
                  <prefer>
                      <family>emoji</family>
                  </prefer>
              </alias>
              <alias binding="weak">
                  <family>serif</family>
                  <prefer>
                      <family>emoji</family>
                  </prefer>
              </alias>

              <match target="pattern">
                <test qual="any" name="family">
                  <string>monospace</string>
                </test>
                <edit name="family" mode="assign" binding="same">
                  <string>monospace</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="family">
                  <string>"monospace"</string>
                </test>
                <edit name="family" mode="prepend">
                  <string>monospace</string>
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
      targets.nixvim.enable = false;

      image = pkgs.nixicle.wallpapers.earth;

      cursor = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 24;
      };

      fonts = {
        sizes = {
          terminal = 14;
          applications = 12;
          popups = 12;
        };

        serif = {
          name = "Source Serif";
          package = pkgs.source-serif;
        };

        sansSerif = {
          name = "Noto Sans";
          package = pkgs.noto-fonts;
        };

        monospace = {
          package = pkgs.nixicle.monolisa;
          name = "MonoLisa Nerd Font";
        };

        emoji = {
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
        };
      };
    };
  };
}

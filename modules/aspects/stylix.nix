{ inputs, ... }:
{
  flake-file.inputs.stylix.url = "github:danth/stylix";
  flake-file.inputs.catppuccin.url = "github:catppuccin/nix";

  den.aspects.stylix = {
    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.stylix.nixosModules.stylix ];
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

    homeManager =
      { pkgs, ... }:
      {
        imports = [
          inputs.stylix.homeModules.stylix
          inputs.catppuccin.homeModules.catppuccin
        ];
        fonts.fontconfig.enable = true;
        home.pointerCursor.enable = true;

        home.packages = with pkgs; [
          nerd-fonts.symbols-only
          open-sans
        ];

        catppuccin = {
          enable = true;
          autoEnable = false;
          cache.enable = true;
          flavor = "mocha";
          fish.enable = true;
        };

        stylix = {
          enable = true;
          autoEnable = true;
          base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
          override.base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
          polarity = "dark";

          icons = {
            enable = true;
            package = pkgs.catppuccin-papirus-folders.override {
              flavor = "mocha";
              accent = "lavender";
            };
            dark = "Papirus-Dark";
          };

          targets.firefox = {
            firefoxGnomeTheme.enable = true;
            profileNames = [ "default" ];
          };

          image = pkgs.nixicle.wallpapers.nixppuccin;

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
              name = "MonoLisa";
            };
            emoji = {
              package = pkgs.noto-fonts-color-emoji;
              name = "Noto Color Emoji";
            };
          };
        };
      };
  };
}

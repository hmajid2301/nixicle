{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.programs.starship;
  inherit (config.colorScheme) palette;
in {
  options.cli.programs.starship = with types; {
    enable = mkBoolOpt false "Whether or not to enable starship";
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        palette = "custom";
        palettes.custom = {
          rosewater = "#${palette.base06}";
          flamingo = "#${palette.base0F}";
          pink = "#f6c2e7";
          mauve = "#${palette.base0E}";
          red = "#${palette.base08}";
          maroon = "#eba0ac";
          peach = "#${palette.base09}";
          yellow = "#${palette.base0A}";
          green = "#${palette.base0B}";
          teal = "#${palette.base0C}";
          sky = "#89dceb";
          sapphire = "#74c7ec";
          blue = "#${palette.base0D}";
          lavender = "#${palette.base07}";
          text = "#${palette.base05}";
          subtext1 = "#bac2de";
          subtext0 = "#a6adc8";
          overlay2 = "#9399b2";
          overlay1 = "#7f849c";
          overlay0 = "#6c7086";
          surface2 = "#${palette.base04}";
          surface1 = "#${palette.base03}";
          surface0 = "#${palette.base02}";
          base = "#${palette.base00}";
          mantle = "#${palette.base01}";
          crust = "#11111b";
        };
      };
    };
  };
}

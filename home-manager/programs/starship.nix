{config, ...}: {
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      palette = "custom";
      palettes.custom = {
        rosewater = "#${config.colorscheme.colors.base06}";
        flamingo = "#${config.colorscheme.colors.base0F}";
        pink = "#f6c2e7";
        mauve = "#${config.colorscheme.colors.base0E}";
        red = "#${config.colorscheme.colors.base08}";
        maroon = "#eba0ac";
        peach = "#${config.colorscheme.colors.base09}";
        yellow = "#${config.colorscheme.colors.base0A}";
        green = "#${config.colorscheme.colors.base0B}";
        teal = "#${config.colorscheme.colors.base0C}";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        blue = "#${config.colorscheme.colors.base0D}";
        lavender = "#${config.colorscheme.colors.base07}";
        text = "#${config.colorscheme.colors.base05}";
        subtext1 = "#bac2de";
        subtext0 = "#a6adc8";
        overlay2 = "#9399b2";
        overlay1 = "#7f849c";
        overlay0 = "#6c7086";
        surface2 = "#${config.colorscheme.colors.base04}";
        surface1 = "#${config.colorscheme.colors.base03}";
        surface0 = "#${config.colorscheme.colors.base02}";
        base = "#${config.colorscheme.colors.base00}";
        mantle = "#${config.colorscheme.colors.base01}";
        crust = "#11111b";
      };
    };
  };
}

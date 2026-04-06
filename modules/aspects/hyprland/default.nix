{ den, ... }:
{
  den.aspects.hyprland = {
    includes = [
      den.aspects.kanshi
      den.aspects.hypridle
      den.aspects.hyprlock
      den.aspects.hyprpaper
      den.aspects.swaylock
      den.aspects.waybar
      den.aspects.swaync
    ];

    homeManager = { ... }: {
      imports = [
        ./_config.nix
        ./_keybindings.nix
        ./_windowrules.nix
      ];
    };
  };
}

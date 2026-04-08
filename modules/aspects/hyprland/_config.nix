{ pkgs, config, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    systemd.enableXdgAutostart = true;
    xwayland.enable = true;

    settings = {
      input = {
        kb_layout = "gb";
        touchpad.disable_while_typing = false;
      };
      general = {
        gaps_in = 3;
        gaps_out = 5;
        border_size = 3;
      };
      decoration.rounding = 5;
      misc = {
        vrr = 2; # FULLSCREEN_ONLY
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
      };
      source = [ "${config.home.homeDirectory}/.config/hypr/monitors.conf" ];
      exec-once = [
        "${pkgs.kanshi}/bin/kanshi"
        "${pkgs.clipse}/bin/clipse -listen"
        "${pkgs.solaar}/bin/solaar -w hide"
        "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator"
      ];
    };
  };

  nix.settings = {
    extra-substituters = [ "https://hyprland.cachix.org" ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };
}

{ lib, ... }:
{
  home = {
    username = "haseeb";
    homeDirectory = "/home/haseeb";
    stateVersion = "26.05";
  };

  gtk.gtk4.theme = null;

  dev.claude-code.enable = lib.mkForce false;

  programs.git = {
    signing = {
      format = "ssh";
      signByDefault = true;
    };
  };

  roles = {
    desktop.enable = true;
    development.enable = true;
    gaming.enable = true;
    social.enable = true;
    # video.enable = true;
  };

  desktops = {
    niri.enable = true;
    addons = {
      noctalia.enable = true;
      swayidle = {
        enable = true;
        timeouts = {
          lock = 300;
          dpms = 330;
          suspend = 0;
          hibernate = 0;
        };
      };
    };
  };
}

{
  home = {
    username = "haseeb";
    homeDirectory = "/home/haseeb";
    stateVersion = "24.05";
  };

  roles = {
    desktop.enable = true;
    development.enable = true;
    gaming.enable = true;
    social.enable = true;
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

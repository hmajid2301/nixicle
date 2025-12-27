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
          lock = 300;     # Lock after 5 minutes
          dpms = 330;     # Turn off monitors after 5.5 minutes
          suspend = 0;    # Never auto-suspend
        };
      };
    };
  };
}

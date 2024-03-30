{lib, ...}: {
  suites = {
    desktop.enable = true;
  };

  desktops.hyprland.enable = true;
  desktops.addons = {
    gnome.enable = true;

    swaylock = {
      enable = true;
      blur = "25x20";
      vignette = "0.5x0.5";
      binary = "/usr/local/bin/swaylock";
    };
  };

  cli.programs = {
    git = {
      email = "haseeb.majid@imaginecurve.com";
      urlRewrites = {
        "git@gitlab.com:imaginecurve/" = "https://gitlab.com/imaginecurve/";
        "git@gitlab.com:" = "https://gitlab.com/";
      };
    };
    ssh = {
      extraHosts = {
        "gitlab-personal" = {
          hostname = "gitlab.com";
          identityFile = "~/.ssh/id_ed25519_personal";
        };
      };
    };
  };

  wayland.windowManager.hyprland.keyBinds.bind."SUPER, Return" = lib.mkForce "exec,nixGL -- wezterm";
  wayland.windowManager.hyprland.keyBinds.bindi = lib.mkForce {};

  nixicle.user = {
    enable = true;
    name = "haseebmajid";
  };

  home.stateVersion = "23.11";
}

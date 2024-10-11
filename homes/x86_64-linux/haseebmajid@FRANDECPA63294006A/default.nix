{
  config,
  pkgs,
  lib,
  ...
}: let
  screensharing = pkgs.writeScriptBin "screensharing" ''
    #!/usr/bin/env bash
    sleep 1
    killall -e xdg-desktop-portal-hyprland
    killall -e xdg-desktop-portal-wlr
    killall xdg-desktop-portal
    /usr/libexec/xdg-desktop-portal-hyprland &
    sleep 2
    /usr/libexec/xdg-desktop-portal &
  '';
in {
  imports = [
    # TODO: remove when https://github.com/nix-community/home-manager/pull/5355 gets merged:
    (builtins.fetchurl {
      url = "https://raw.githubusercontent.com/Smona/home-manager/nixgl-compat/modules/misc/nixgl.nix";
      sha256 = "01dkfr9wq3ib5hlyq9zq662mp0jl42fw3f6gd2qgdf8l8ia78j7i";
    })
  ];

  programs = {
    kitty.package = config.lib.nixGL.wrap pkgs.kitty;
    firefox.package = config.lib.nixGL.wrap pkgs.firefox;
  };

  roles = {
    desktop.enable = true;
  };

  home = {
    sessionVariables = {
      DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
    };

    packages = with pkgs; [
      screensharing
    ];
  };

  # wayland.windowManager.hyprland.keyBinds.bind."SUPER, Return" = lib.mkForce "exec, nixGLIntel kitty";

  desktops = {
    hyprland = {
      enable = true;
      execOnceExtras = [
        "warp-taskbar"
        "blueman-applet"
        "${screensharing}/bin/screensharing"
        "nm-applet"
      ];
    };

    gnome.enable = true;
  };

  xdg.configFile."environment.d/envvars.conf".text = ''
    PATH="$PATH:/home/haseebmajid/.nix-profile/bin"
  '';

  cli.programs = {
    git = {
      allowedSigners = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOEtfQ0znAH8QyB4Z5FzRPa9iKkBhuriEpqyfoEkiv+ haseeb.majid@imaginecurve.com";
      email = "haseeb.majid@imaginecurve.com";
      urlRewrites = {
        "git@gitlab.com:imaginecurve/" = "https://gitlab.com/imaginecurve/";
        "git@gitlab.com:" = "https://gitlab.com";
      };
    };
    ssh = {
      extraHosts = {
        "gitlab-personal" = {
          hostname = "gitlab.com";
          identityFile = "~/.ssh/id_ed25519_personal";
        };
        "gitlab.com" = {
          hostname = "gitlab.com";
          identityFile = "~/.ssh/id_ed25519";
        };
      };
    };
  };

  nixicle.user = {
    enable = true;
    name = "haseebmajid";
  };

  home.stateVersion = "23.11";
}

{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: {
  imports = [
    ../../home-manager
  ];

  config = {
    wayland.windowManager.hyprland.keyBinds.bindi = lib.mkForce {};

    my.settings = {
      wallpaper = "~/dotfiles/home-manager/wallpapers/Kurzgesagt-Galaxy_3.png";
      host = "curve";
      default = {
        shell = "fish";
        terminal = "wezterm";
        browser = "firefox";
        editor = "nvim";
      };
    };

    colorscheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;

    home = {
      username = lib.mkDefault "haseebmajid";
      homeDirectory = lib.mkDefault "/home/${config.home.username}";
      stateVersion = lib.mkDefault "23.05";
    };

    modules = {
      browsers = {
        firefox.enable = true;
      };

      editors = {
        nvim.enable = true;
      };

      multiplexers = {
        zellij.enable = true;
      };

      wms = {
        hyprland.enable = true;
      };

      shells = {
        fish.enable = true;
      };

      terminals = {
        foot.enable = true;
        wezterm.enable = true;
      };
    };

    # To show nix installed apps in Gnome
    xdg = {
      mime.enable = true;
      systemDirs.data = ["${config.home.homeDirectory}/.nix-profile/share/applications"];
      configFile."git/ignore".text = ''
        projects/**/**/flake.nix
        projects/**/**/flake.lock
      '';
    };
    targets.genericLinux.enable = true;

    # Work Laptop different email
    programs = {
      git = {
        userEmail = lib.mkForce "haseeb.majid@imaginecurve.com";
        extraConfig = {
          "url \"git@git.curve.tools:\"" = {insteadOf = "https://git.curve.tools/";};
          "url \"git@gitlab.com:imaginecurve/\"" = {insteadOf = "https://gitlab.com/imaginecurve/";};
          "url \"git@gitlab.com:\"" = {insteadOf = "https://gitlab.com/";};
          core.excludesfile = "~/.config/git/ignore";
        };
      };
      swaylock = {
        settings.effect-blur = lib.mkForce "25x20";
        settings.effect-vignette = lib.mkForce "0.5x0.5";
      };
    };

    wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
      exec-once = /usr/libexec/geoclue-2.0/demos/agent
      exec-once = warp-taskbar

      bind=,XF86Launch5,exec,/usr/local/bin/swaylock -S
      bind=,XF86Launch4,exec,/usr/local/bin/swaylock -S
      bind=SUPER,backspace,exec,/usr/local/bin/swaylock -S
      bind=SUPER,return,exec,nixGL -- wezterm
      bind=,XF86AudioRaiseVolume,exec, ${pkgs.pamixer}/bin/pamixer -i 5
      bind=,XF86AudioLowerVolume,exec, ${pkgs.pamixer}/bin/pamixer -d 5
    '';

    home.packages = with pkgs; [
      podman-compose
      podman-tui
      docker-compose
    ];

    gtk.iconTheme = lib.mkForce {
      package = pkgs.gnome.adwaita-icon-theme;
      name = "Adwaita";
    };

    services.swayidle = lib.mkForce {
      enable = true;
      events = [
        {
          event = "before-sleep";
          command = "/usr/local/bin/swaylock -fF";
        }
        {
          event = "lock";
          command = "/usr/local/bin/swaylock -fF";
        }
      ];
      timeouts = [
        {
          timeout = 600;
          command = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms off";
          resumeCommand = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch dpms on";
        }
        {
          timeout = 610;
          command = "${pkgs.systemd}/bin/loginctl lock-session";
        }
      ];
    };
  };
}

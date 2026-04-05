{ den, ... }:
{
  den.aspects.desktop = {
    includes = [
      den.aspects.common
      den.aspects.development
      den.aspects.niri
      den.aspects.audio
      den.aspects.vpn
    ];

    nixos = { lib, pkgs, ... }: {
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = false;
          settings.General.Experimental = true;
        };
        # Logitech wireless mouse
        logitech.wireless = {
          enable = true;
          enableGraphical = true;
        };
        # ZSA keyboards (Moonlander, Voyager, etc.)
        keyboard.zsa.enable = true;
      };
      services = {
        upower.enable = true;
        blueman.enable = true;
        avahi = {
          enable = true;
          nssmdns4 = true;
          publish = {
            enable = true;
            addresses = true;
            domain = true;
            hinfo = true;
            userServices = true;
            workstation = true;
          };
        };
      };
      environment.systemPackages = with pkgs; [
        solaar
      ];
      services.udev.packages = with pkgs; [
        logitech-udev-rules
        solaar
      ];
      boot.plymouth.enable = true;
      boot.kernelParams = [ "quiet" "splash" "loglevel=3" "udev.log_level=0" ];
      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
        flake = "/home/haseeb/nixicle";
      };
      nix.gc.automatic = lib.mkForce false;
    };

    homeManager = { pkgs, ... }: {
      systemd.user.targets.tray = {
        Unit = {
          # tray icons require graphical-session-pre: https://github.com/nix-community/home-manager/issues/2064
          Description = "Home Manager System Tray";
          Requires = [ "graphical-session-pre.target" ];
        };
      };
      services.spotify.enable = true;

      xdg.desktopEntries = {
        "org.kde.kdeconnect.sms" = { exec = ""; name = "KDE Connect SMS"; settings.NoDisplay = "true"; };
        "org.kde.kdeconnect.nonplasma" = { exec = ""; name = "KDE Connect Indicator"; settings.NoDisplay = "true"; };
        "org.kde.kdeconnect.app" = { exec = ""; name = "KDE Connect"; settings.NoDisplay = "true"; };
      };
      qt.enable = true;
      xdg.configFile."autostart/polkit-kde-authentication-agent-1.desktop".text = ''
        [Desktop Entry]
        Hidden=true
      '';
      desktops.addons.xdg.enable = true;
      home.sessionVariables = {
        MOZ_ENABLE_WAYLAND = 1;
        QT_QPA_PLATFORM = "wayland;xcb";
        LIBSEAT_BACKEND = "logind";
        EDITOR = "nixCats";
        MANPAGER = "nixCats +Man!";
      };
      home.packages = with pkgs; [
        ddcutil
        mtpfs
        jmtpfs
        brightnessctl
        xdg-utils
        wl-clipboard
        clipse
        pamixer
        playerctl
        impression
        grimblast
        slurp
        sway-contrib.grimshot
        satty
      ];
    };
  };
}

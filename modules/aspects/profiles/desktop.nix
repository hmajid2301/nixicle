{ den, ... }:
{
  den.aspects.desktop = {
    includes = [
      den.aspects.common
      den.aspects.development
      den.aspects.niri
      den.aspects.audio
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
        vpn.enable = true;
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
      system.boot.plymouth = true;
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
      services = {
        nixicle.kdeconnect.enable = true;
        spotify.enable = true;
      };
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

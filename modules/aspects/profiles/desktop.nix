{ den, ... }:
{
  den.aspects.desktop = {
    includes = [
      den.aspects.common
      den.aspects.development
      den.aspects.niri
    ];

    nixos = { lib, ... }: {
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
      hardware = {
        audio.enable = true;
        bluetooth.enable = true;
        logitechMouse.enable = true;
        zsa.enable = true;
      };
      services = {
        nixicle.avahi.enable = true;
        vpn.enable = true;
        upower.enable = true;
      };
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

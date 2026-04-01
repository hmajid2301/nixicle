# desktop aspect — replaces roles.desktop.enable = true on both NixOS and home-manager.
# Includes the common aspect as a dependency.
{ den, ... }:
{
  den.aspects.desktop = {
    includes = [ den.aspects.common ];

    # NixOS side: audio, bluetooth, peripherals, display tools
    nixos = { ... }: {
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
      cli.programs = {
        nh.enable = true;
        nix-ld.enable = true;
      };
    };

    # Home-manager side: tray target, kdeconnect, spotify, packages
    homeManager = { pkgs, ... }: {
      roles.development.enable = true; # still using option-based sub-roles for now

      systemd.user.targets.tray = {
        Unit = {
          Description = "Home Manager System Tray";
          Requires = [ "graphical-session-pre.target" ];
        };
      };

      services.nixicle.kdeconnect.enable = true;
      services.spotify.enable = true;
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

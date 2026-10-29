{
  config,
  pkgs,
  lib,
  inputs,
  hostIsLaptop,
  ...
}:
{
  options.nixicle.desktop.niri.startup = {
    xwaylandArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Arguments used for the xwayland-satellite startup command.";
    };

    extraCommands = lib.mkOption {
      type = lib.types.listOf (lib.types.listOf lib.types.str);
      description = "Additional startup commands shared across hosts.";
    };
  };

  config = {
    home.packages =
      with pkgs;
      [
        cliphist
        wl-clipboard
        wdisplays
        glib.bin
        sshfs
        upower
      ]
      ++ (with inputs.nfsm.packages.${pkgs.stdenv.hostPlatform.system}; [
        nfsm
        nfsm-cli
      ]);

    nixicle.desktop.niri.startup = {
      xwaylandArgs = lib.mkDefault [ "xwayland-satellite" ];
      extraCommands = lib.mkDefault [ [ "nfsm" ] ];
    };

    wayland.windowManager.niri = {
      enable = true;
      package = pkgs.niri;
      xwaylandSatellitePackage = pkgs.xwayland-satellite;
      settings = lib.mkMerge [
        (import ./_settings/core.nix { inherit lib config; })
        (import ./_settings/binds.nix)
        (import ./_settings/startup.nix { inherit lib config; })
        (import ./_settings/rules.nix { inherit lib; })
        (import ./_settings/lid.nix {
          inherit
            pkgs
            config
            hostIsLaptop
            lib
            ;
        })
      ];
    };
  };
}

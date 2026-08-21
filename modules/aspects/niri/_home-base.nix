{
  config,
  pkgs,
  inputs,
  hostIsLaptop,
  ...
}:
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia.enable = true;

  home.packages =
    with pkgs;
    [
      bitwarden-cli
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

  xdg.configFile = {
  };

  wayland.windowManager.niri = {
    enable = true;
    package = pkgs.niri;
    xwaylandSatellitePackage = pkgs.xwayland-satellite;
    extraConfig = import ./_extra-config.nix { inherit pkgs config hostIsLaptop; };
  };
}

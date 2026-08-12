{
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [ inputs.noctalia.homeModules.default ];

  home.packages =
    with pkgs;
    [
      cliphist
      wl-clipboard
      wdisplays
    ]
    ++ (with inputs.nfsm.packages.${pkgs.stdenv.hostPlatform.system}; [
      nfsm
      nfsm-cli
    ]);

  xdg.configFile = {
    "noctalia/plugins/display-config".source = "${inputs.noctalia-plugins}/display-config";
    "noctalia/plugins/rbw-provider".source = "${inputs.noctalia-plugins}/rbw-provider";
  };

  wayland.windowManager.niri = {
    enable = true;
    package = pkgs.niri;
    xwaylandSatellitePackage = pkgs.xwayland-satellite;
    extraConfig = import ./_extra-config.nix { };
  };
}

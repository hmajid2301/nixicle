{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.nixicle;
with types;
let
  cfg = config.desktops.niri;
in
{
  imports = [
    ./config.nix
    ./keybindings.nix
  ];

  options.desktops.niri = {
    enable = mkEnableOption "Enable niri window manager";

    extraPackages = mkOpt (listOf package) [ ] "Extra packages to install for niri";
    extraStartupApps = mkOpt (listOf (listOf str)) [ ] "Extra applications to spawn at startup";
    outputs = mkOpt attrs { } "Output-specific configuration (monitors/displays)";
  };

  config = mkIf cfg.enable {
    nix.settings = {
      extra-substituters = [ "https://niri.cachix.org" ];
      extra-trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
    };

    stylix.targets.niri.enable = lib.mkDefault true;

    desktops.addons = {
      rofi.enable = true;
      wlsunset.enable = true;
      noctalia.enable = true;
      wlogout.enable = true;
      cliphist.enable = true;
      cava.enable = true;
      swayidle.enable = true;
    };

    home.packages = with inputs.nfsm.packages.${pkgs.stdenv.hostPlatform.system}; [
      nfsm
      nfsm-cli
    ];

    desktops.niri.extraStartupApps = [
      [ "nfsm" ]
    ];
  };
}

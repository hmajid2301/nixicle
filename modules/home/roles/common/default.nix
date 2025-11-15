{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.roles.common;
in
{
  options.roles.common = {
    enable = lib.mkEnableOption "Enable common configuration";
  };

  config = lib.mkIf cfg.enable {
    browsers.firefox.enable = true;

    system = {
      nix.enable = true;
    };

    cli = {
      terminals.foot.enable = true;
      terminals.ghostty.enable = true;
      programs.k8s.enable = true;
      programs.core-tools.enable = true;
      shells.fish.enable = true;
    };

    programs = {
      guis.enable = true;
    };

    security = {
      sops.enable = true;
    };

    # Hardware support
    hardware.zsa-keyboard.enable = true;

    styles.stylix.enable = true;
  };
}

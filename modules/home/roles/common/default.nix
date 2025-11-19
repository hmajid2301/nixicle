{delib, ...}:
delib.module {
  name = "roles-common";

  options.roles.common = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  let
    cfg = config.roles.common;
  in
  lib.mkIf cfg.enable {
    browsers.firefox.enable = true;

    system = {
      nix.enable = true;
    };

    cli = {
      terminals.foot.enable = true;
      terminals.ghostty.enable = true;
      tools.core-tools.enable = true;
      tools.zk.enable = true;
      shells.fish.enable = true;
    };

    development.cloud.k8s.enable = true;

    programs = {
      guis.enable = true;
    };

    security = {
      sops.enable = true;
    };

    hardware.zsa-keyboard.enable = true;

    styles.stylix.enable = true;
  };
}

{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib;
with inputs; let
  cfg = config.roles.common;
in {
  imports = [
    catppuccin.homeManagerModules.catppuccin
    nix-colors.homeManagerModule
  ];

  options.roles.common = {
    enable = mkEnableOption "Enable common configuration";
  };

  config = mkIf cfg.enable {
    colorscheme = nix-colors.colorSchemes.catppuccin-mocha;
    catppuccin = {
      enable = true;
      flavor = "mocha";
    };

    browsers.firefox.enable = true;

    system = {
      nix.enable = true;
      fonts.enable = true;
    };

    cli = {
      terminals.foot.enable = true;
      shells.fish.enable = true;
    };
    programs = {
      guis.enable = true;
      tuis.enable = true;
    };

    security = {
      sops.enable = true;
    };

    # TODO: move this to a separate module
    home.packages = with pkgs;
    with pkgs.nixicle; [
      monolisa
      lisa

      keymapp
      powertop

      src-cli

      (lib.hiPrio parallel)
      moreutils
      nvtopPackages.amd
      unzip
      gnupg

      showmethekey
    ];
  };
}

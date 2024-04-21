{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib;
with inputs; let
  cfg = config.suites.common;
in {
  imports = [
    catppuccin.homeManagerModules.catppuccin
    nix-colors.homeManagerModule
  ];

  options.suites.common = {
    enable = mkEnableOption "Enable common configuration";
  };

  config = mkIf cfg.enable {
    colorscheme = nix-colors.colorSchemes.catppuccin-mocha;
    catppuccin.flavour = "mocha";

    browsers.firefox.enable = true;

    system = {
      nix.enable = true;
      fonts.enable = true;
    };

    cli = {
      terminals.foot.enable = true;
      terminals.kitty.enable = true;
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

      keymapp
      powertop

      src-cli

      (lib.hiPrio parallel)
      moreutils
      nvtopPackages.amd
      htop
      unzip
      gnupg

      showmethekey
    ];
  };
}

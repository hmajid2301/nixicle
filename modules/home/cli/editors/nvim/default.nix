{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
with lib;
with lib.nixicle;
with inputs; let
  cfg = config.cli.editors.nvim;
in {
  imports =
    [
      nixvim.homeManagerModules.nixvim
    ]
    ++ lib.snowfall.fs.get-non-default-nix-files ./.;

  options.cli.editors.nvim = with types; {
    enable = mkBoolOpt false "enable neovim editor";
  };

  config =
    mkIf
    cfg.enable
    {
      programs.nixvim = {
        enable = true;
        extraPlugins = with pkgs.vimPlugins; [plenary-nvim];
      };
    };
}

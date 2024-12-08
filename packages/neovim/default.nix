{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
pkgs.nixvim.makeNixvimWithModule {
  inherit pkgs;

  module = {
    imports = ../.../../moules/home/cli/editors/nvim;
  };
}

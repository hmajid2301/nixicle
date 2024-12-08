{
  lib,
  pkgs,
  inputs,
  config,
  ...
}: let
  neovim = [
    (import ../../modules/home/cli/editors/nvim {
      inherit pkgs lib inputs config;
    })
  ];
in {inherit neovim;}

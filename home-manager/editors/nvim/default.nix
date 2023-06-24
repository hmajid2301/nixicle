{ pkgs, ... }:
{
  home.file."./.config/nvim/" = {
    source = ./config;
    recursive = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  home.packages = with pkgs; [
    # parser (nvim)
    tree-sitter
    wget
    python311Packages.pip
    python311Packages.pillow
  ];
}

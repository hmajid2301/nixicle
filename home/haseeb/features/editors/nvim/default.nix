{pkgs, ...}:
{
  home.file."./.config/nvim/" = {
    source = ./config;
    recursive = true;
  };

  programs.neovim = {
    enable = true;
  };

  home.packages = with pkgs; [
    # parser (nvim)
    tree-sitter
  ];
}

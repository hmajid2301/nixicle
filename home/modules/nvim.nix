{pkgs, ...}:
{
  home.file."./.config/nvim/" = {
    source = ./nvim;
    recursive = true;
  };
}

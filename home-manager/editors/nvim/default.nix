{ ... }:
{
  # TODO: Old LazyVim config, slowly being ported to nixvim
  home.file."./.config/" = {
    source = ./config;
    recursive = true;
  };

  imports = [
    ./plugins/colorscheme.nix
    ./plugins/treesitter.nix
    ./plugins/telescope.nix
    ./plugins/startup.nix
    ./plugins/editor.nix

    ./plugins/ui.nix

    ./plugins/keymaps.nix
    ./plugins/options.nix

    ./plugins/langs/go.nix
  ];

  programs.nixvim = {
    enable = true;
  };
}

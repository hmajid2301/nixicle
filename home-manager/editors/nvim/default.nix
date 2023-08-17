{...}: {
  # NOTE: neovim distribution config (LazyVim, NvChad)
  home.file."./.config/" = {
    source = ./config;
    recursive = true;
  };

  imports = [
    ./plugins/editor.nix
    ./plugins/debug.nix
    ./plugins/session.nix
    ./plugins/startup.nix
    ./plugins/telescope.nix

    ./plugins/lsp.nix
    ./plugins/treesitter.nix

    ./plugins/colorscheme.nix
    ./plugins/ui.nix

    ./plugins/keymaps.nix
    ./plugins/options.nix

    ./plugins/langs/go.nix
    ./plugins/langs/lua.nix
    ./plugins/langs/nix.nix
    ./plugins/tmux.nix
  ];

  programs.nixvim = {
    enable = true;
  };
}

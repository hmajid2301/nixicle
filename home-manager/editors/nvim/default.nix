{...}: {
  # NOTE: neovim distribution config (LazyVim, NvChad)
  home.file."./.config/" = {
    source = ./config;
    recursive = true;
  };

  imports = [
    ./plugins/editor.nix
    ./plugins/debug.nix
    ./plugins/git.nix
    ./plugins/session.nix
    ./plugins/startup.nix
    ./plugins/test.nix

    ./plugins/lsp.nix
    ./plugins/treesitter.nix

    ./plugins/colorscheme.nix
    ./plugins/ui.nix

    ./plugins/keymaps.nix
    ./plugins/options.nix

    ./plugins/lang/go.nix
    ./plugins/lang/lua.nix
    ./plugins/lang/nix.nix
    ./plugins/tmux.nix
  ];

  programs.nixvim = {
    enable = true;
  };
}

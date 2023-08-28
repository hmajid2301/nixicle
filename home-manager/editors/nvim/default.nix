{pkgs, ...}: {
  home.file."./.config/nvim" = {
    source = ./config;
    recursive = true;
  };

  imports = [
    ./plugins/debug.nix
    ./plugins/coding.nix
    ./plugins/editor.nix
    ./plugins/git.nix
    ./plugins/startup.nix
    ./plugins/test.nix

    ./plugins/lsp.nix
    ./plugins/treesitter.nix

    ./plugins/colorscheme.nix
    ./plugins/ui.nix
    ./plugins/keymaps.nix
    ./plugins/options.nix

    ./plugins/ai.nix
    ./plugins/training.nix

    ./plugins/lang/go.nix
    ./plugins/lang/lua.nix
    ./plugins/lang/nix.nix
    ./plugins/lang/markdown.nix
    ./plugins/lang/yaml.nix
    ./plugins/tmux.nix
  ];

  programs.nixvim = {
    enable = true;
    extraPlugins = with pkgs.vimPlugins; [plenary-nvim];
  };
}

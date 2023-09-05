{ pkgs
, config
, ...
}: {
  programs.nixvim = {
    plugins.lsp.servers.nixd = {
      enable = true;
    };

    extraConfigVim =
      # vim
      ''
        au BufRead,BufNewFile flake.lock setf json
      '';

    plugins.treesitter = {
      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        nix
      ];
    };

    plugins.nix.enable = true;
    extraPlugins = with pkgs; [ hmts-nvim ];
  };
}

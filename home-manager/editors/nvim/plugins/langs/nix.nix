{ pkgs, config, ... }: {
  programs.nixvim = {
    plugins.lsp.servers.nil_ls = {
      enable = true;
      settings = {
        formatting.command = [ "${pkgs.alejandra}/bin/alejandra" ];
      };
    };

    extraConfigVim = /* vim */ ''
      au BufRead,BufNewFile flake.lock setf json
    '';

    plugins.treesitter = {
      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        nix
      ];
    };

    extraPlugins = with pkgs; [ hmts-nvim ];
  };
}
  

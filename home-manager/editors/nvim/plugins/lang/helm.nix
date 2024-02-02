{pkgs, ...}: {
  programs.nixvim = {
    extraPackages = with pkgs; [
      helm-ls
    ];

    extraPlugins = with pkgs.vimPlugins; [
      vim-helm
    ];
    extraConfigLua =
      # lua
      ''
        local lspconfig = require('lspconfig')

        -- setup helm-ls
        lspconfig.helm_ls.setup {
        	settings = {
        		['helm-ls'] = {
        			yamlls = {
        				path = "${pkgs.yaml-language-server}/bin/yaml-language-server",
        			}
        		}
        	}
        }
      '';
  };
}

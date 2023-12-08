{ config
, pkgs
, ...
}: {
  home.packages = with pkgs;  [
    zk
    marksman
  ];

  sops.secrets.languagetool_username = {
    sopsFile = ../../../../secrets.yaml;
  };

  sops.secrets.languagetool_api_key = {
    sopsFile = ../../../../secrets.yaml;
  };

  programs.nixvim = {
    plugins = {
      lsp.servers = {
        ltex = {
          enable = true;
          filetypes = [
            "markdown"
            "text"
          ];

          settings = {
            completionEnabled = true;
            # languageToolHttpServerUri = "https://api.languagetoolplus.com";
            # languageToolOrg = {
            #   # I know this is insecure and puts the values into the nix store.
            #   # Need to come up with a better method. But I am the only one
            #   username = builtins.readFile config.sops.secrets.languagetool_username.path;
            #   apiKey = builtins.readFile config.sops.secrets.languagetool_api_key.path;
            # };
          };

          extraOptions = {
            checkFrequency = "save";
            language = "en-GB";
          };
        };
      };

      zk = {
        enable = true;
        picker = "telescope";
      };
    };

    extraConfigLua =
      ''
        require'lspconfig'.marksman.setup{}
        local function markdown_sugar()
        local augroup = vim.api.nvim_create_augroup('markdown', {})
        vim.api.nvim_create_autocmd('BufEnter', {
        	pattern = '*.md',
        	group = augroup,
        	callback = function()
        		vim.api.nvim_set_hl(0, 'Conceal', { bg = 'NONE', fg = '#00cf37' })
        		vim.api.nvim_set_hl(0, 'todoCheckbox', { link = 'Todo' })
        		vim.bo.conceallevel = 1

        		vim.cmd [[
        			syn match todoCheckbox '\v(\s+)?(-|\*)\s\[\s\]'hs=e-4 conceal cchar=
        			syn match todoCheckbox '\v(\s+)?(-|\*)\s\[x\]'hs=e-4 conceal cchar=
        			syn match todoCheckbox '\v(\s+)?(-|\*)\s\[-\]'hs=e-4 conceal cchar=󰅘
        			syn match todoCheckbox '\v(\s+)?(-|\*)\s\[\.\]'hs=e-4 conceal cchar=⊡
        			syn match todoCheckbox '\v(\s+)?(-|\*)\s\[o\]'hs=e-4 conceal cchar=⬕
        		]]
        	end
        })
        end

        markdown_sugar()
      '';

    plugins.treesitter = {
      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        markdown
        markdown_inline
      ];
    };
  };
}

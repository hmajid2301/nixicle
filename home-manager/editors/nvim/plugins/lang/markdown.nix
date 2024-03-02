{
  config,
  pkgs,
  ...
}: let
  pastify = pkgs.vimUtils.buildVimPlugin rec {
    version = "47317b9bb7bf5fb7dfd994a6eb9bec8f00628dc0";
    pname = "pastify.nvim";
    src = pkgs.fetchFromGitHub {
      owner = "TobinPalmer";
      repo = pname;
      rev = "${version}";
      sha256 = "sha256-qNayJtPJe90KkPbVyqvenWovFOx5pwmx6wqQDa3fgJQ=";
    };
  };
in {
  home.packages = with pkgs; [
    marksman
  ];

  sops.secrets.languagetool_username = {
    sopsFile = ../../../../secrets.yaml;
  };

  sops.secrets.languagetool_api_key = {
    sopsFile = ../../../../secrets.yaml;
  };

  programs.nixvim = {
    extraPlugins = [
      pastify
    ];
    extraConfigLua = ''
      require("pastify").setup {
        opts = {
          local_path = '/images/',
        },
      }
    '';
    extraPython3Packages = p: [
      p.pillow
    ];

    plugins = {
      image = {
        enable = true;
        integrations.markdown = {
          clearInInsertMode = true;
          onlyRenderImageAtCursor = true;
        };
      };

      lsp.servers = {
        marksman = {
          enable = true;
        };

        ltex = {
          enable = true;
          filetypes = [
            "markdown"
            "text"
          ];

          settings = {
            completionEnabled = true;
          };

          extraOptions = {
            checkFrequency = "save";
            language = "en-GB";
          };
        };
      };
    };

    plugins.treesitter = {
      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        markdown
        markdown_inline
      ];
    };
  };
}

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
      '';

    plugins.treesitter = {
      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        markdown
        markdown_inline
      ];
    };
  };
}

{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    docker-compose-language-service
  ];

  programs.nixvim = {
    extraConfigLua = ''
      require("lspconfig")["docker_compose_language_service"].setup({})
    '';

    plugins = {
      lsp.servers.dockerls.enable = true;

      lint = {
        lintersByFt = {
          docker = ["hadolint"];
        };

        linters = {
          hadolint = {
            cmd = "${pkgs.hadolint}/bin/hadolint";
          };
        };
      };

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          dockerfile
        ];
      };
    };
  };
}

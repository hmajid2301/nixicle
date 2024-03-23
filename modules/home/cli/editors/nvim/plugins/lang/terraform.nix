{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    plugins = {
      lsp.servers.terraformls = {
        enable = true;
      };

      conform-nvim = {
        formattersByFt = {
          tf = ["terraform_fmt"];
          terraform = ["terraform_fmt"];
        };

        formatters = {
          terraform_fmt = {
            command = "${pkgs.terraform}/bin/terraform fmt";
          };
        };
      };

      # lint = {
      #   lintersByFt = {
      #     go = ["golangcilint"];
      #   };
      #   linters = {
      #     golangcilint = {
      #       cmd = "${pkgs.golangci-lint}/bin/golangci-lint";
      #     };
      #   };
      # };

      treesitter = {
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          terraform
          hcl
        ];
      };
    };
  };
}

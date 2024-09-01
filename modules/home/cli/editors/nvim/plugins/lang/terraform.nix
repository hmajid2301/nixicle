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
        settings = {
          formatters_by_ft = {
            tf = ["terraform_fmt"];
            terraform = ["terraform_fmt"];
          };

          formatters = {
            terraform_fmt = {
              command = "${pkgs.terraform}/bin/terraform fmt";
            };
          };
        };
      };
    };
  };
}

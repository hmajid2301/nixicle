{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    files = {
      "ftplugin/yaml.lua" = {
        opts = {
          expandtab = false;
          shiftwidth = 2;
          tabstop = 2;
        };
      };
    };

    plugins = {
      lsp.servers.yamlls = {
        enable = true;
        extraOptions = {
          capabilities = {
            textDocument = {
              foldingRange = {
                dynamicRegistration = false;
                lineFoldingOnly = true;
              };
            };
          };
        };
      };

      lint = {
        lintersByFt = {
          yml = ["yamllint"];
          yaml = ["yamllint"];
        };
        linters = {
          yamllint = {
            cmd = "${pkgs.yamllint}/bin/yamllint";
            args = ["-formatter" "retain_line_breaks=true"];
          };
        };
      };
    };
  };
}

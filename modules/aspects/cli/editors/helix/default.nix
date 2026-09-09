{ inputs, ... }:
{
  den.aspects.helix = {
    homeManager =
      { pkgs, ... }:
      {
        programs.helix = {
          enable = true;
          extraPackages = with pkgs; [
            gopls
            delve
            golines
            nixd
            nixfmt
          ];

          languages = {
            language = [
              {
                name = "go";
                auto-format = true;
                formatter = {
                  command = "golines";
                  args = [ "--max-len=100" ];
                };
              }
              {
                name = "nix";
                auto-format = true;
                language-servers = [ "nixd" ];
              }
            ];
            language-server = {
              gopls = {
                config = {
                  gofumpt = true;
                  staticcheck = true;
                  completeUnimported = true;
                  analyses = {
                    shadow = true;
                    unusedparams = true;
                    useany = true;
                  };
                };
              };
              nixd = {
                config = {
                  nixd = {
                    nixpkgs.expr = "import ${inputs.nixpkgs} {}";
                    formatting.command = [ "nixfmt" ];
                    diagnostic.suppress = [ "sema-escaping-with" ];
                  };
                };
              };
            };
          };

          settings = {
            editor = {
              line-number = "relative";
              cursor-shape.insert = "bar";
              bufferline = "multiple";
              idle-timeout = 50;
              indent-guides.render = true;
              soft-wrap.enable = true;
              lsp = {
                display-inlay-hints = true;
                display-messages = true;
              };
            };
          };
        };
      };
  };
}

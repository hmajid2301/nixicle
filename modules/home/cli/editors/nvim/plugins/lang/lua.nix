{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    files = {
      "ftplugin/lua.lua" = {
        opts = {
          expandtab = true;
          shiftwidth = 4;
          tabstop = 4;
        };
      };
    };

    plugins = {
      lsp.servers.lua_ls.enable = true;

      conform-nvim = {
        settings = {
          formatters_by_ft = {
            lua = ["stylua"];
          };

          formatters = {
            stylua = {
              command = "${pkgs.stylua}/bin/stylua";
            };
          };
        };
      };

      lint = {
        lintersByFt = {
          lua = ["luacheck"];
        };
        linters = {
          luacheck = {
            cmd = "${pkgs.lua54Packages.luacheck}/bin/luacheck";
          };
        };
      };
    };
  };
}

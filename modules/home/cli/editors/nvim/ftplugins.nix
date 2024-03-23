{
  programs.nixvim = {
    files = {
      "ftplugin/nix.lua" = {
        options = {
          expandtab = true;
          shiftwidth = 2;
          tabstop = 2;
        };
      };
      "ftplugin/go.lua" = {
        options = {
          expandtab = true;
          shiftwidth = 4;
          tabstop = 4;
        };
      };
      "ftplugin/js.lua" = {
        options = {
          expandtab = true;
          shiftwidth = 2;
          tabstop = 2;
        };
      };
      "ftplugin/lua.lua" = {
        options = {
          expandtab = true;
          shiftwidth = 4;
          tabstop = 4;
        };
      };
      "ftplugin/markdown.lua" = {
        options = {
          expandtab = true;
          shiftwidth = 2;
          tabstop = 2;
        };
      };
      "ftplugin/sql.lua" = {
        options = {
          expandtab = true;
          shiftwidth = 4;
          tabstop = 4;
        };
      };
      "ftplugin/ts.lua" = {
        options = {
          expandtab = true;
          shiftwidth = 2;
          tabstop = 2;
        };
      };
      "ftplugin/yaml.lua" = {
        options = {
          expandtab = false;
          shiftwidth = 2;
          tabstop = 2;
        };
      };
    };
  };
}

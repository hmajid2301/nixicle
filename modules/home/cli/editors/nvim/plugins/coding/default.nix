{lib, ...}: {
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  programs.nixvim = {
    plugins = {
      mini = {
        enable = true;
        modules = {
          surround = {
            mappings = {
              add = "gsa";
              delete = "gsd";
              find = "gsf";
              find_left = "gsF";
              highlight = "gsh";
              replace = "gsr";
              update_n_lines = "gsn";
            };
          };
          comment = {};
          files = {};
          pairs = {};
          trailspace = {};
        };
      };

      friendly-snippets = {
        enable = true;
      };

      luasnip = {
        enable = true;
      };
    };
  };
}

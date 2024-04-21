{lib, ...}: {
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  programs.nixvim = {
    plugins = {
      mini = {
        enable = true;
        modules = {
          surround = {};
          comment = {};
          files = {};
          pairs = {
            mappings = {
              "\"" = {neigh_pattern = "[^\\][%s%)%]}]";};
            };
          };
          trailspace = {};
        };
      };

      friendly-snippets = {
        enable = true;
      };

      luasnip = {
        enable = true;
        fromLua = [
          {
            paths = ./snippets;
          }
        ];
      };
    };
  };
}

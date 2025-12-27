{ config, inputs, ... }:
let
  # Access stylix colors for passing to Neovim
  stylixColors = config.lib.stylix.colors.withHashtag or { };
in
{
  packageDefinitions.replace = {
    nixCats =
      { pkgs, ... }:
      {
        settings = {
          wrapRc = true;
          suffix-path = true;
          suffix-LD = true;
          neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim;
        };
        categories = {
          general = true;
          neonixdev = true;

          css = true;
          docker = true;
          html = true;
          ts = true;
          go = true;
          json = true;
          lua = true;
          markdown = true;
          nix = true;
          python = true;
          sql = true;
          terraform = true;
          toml = true;
          templ = true;
          typescript = true;
          yaml = true;

          ai = true;
          diagnostics = true;
          editor = true;
          debug = true;
          notes = true;
          test = true;
          lint = true;
          format = true;
          git = true;
          ui = true;
          extra = true;

          lspDebugMode = false;
          themer = true;
          colorscheme = "catppuccin";

          # Pass stylix colors to Lua
          colors = stylixColors;
        };
        extra = {
          nixdExtras = {
            inherit (inputs) nixpkgs;
            flake-path = inputs.self;
          };
        };
      };

    regularCats =
      { pkgs, ... }:
      {
        settings = {
          wrapRc = false;
          suffix-path = true;
          suffix-LD = true;
          aliases = [ "nvim" ];
          configDirName = "nvim";
          unwrappedCfgPath = "${config.home.homeDirectory}/nixicle/modules/home/cli/editors/neovim";
          neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim;
        };
        categories = {
          general = true;
          neonixdev = true;

          css = true;
          docker = true;
          html = true;
          go = true;
          ts = true;
          json = true;
          lua = true;
          markdown = true;
          nix = true;
          python = true;
          sql = true;
          terraform = true;
          toml = true;
          templ = true;
          typescript = true;
          yaml = true;

          ai = true;
          diagnostics = true;
          editor = true;
          debug = true;
          notes = true;
          test = true;
          lint = true;
          format = true;
          git = true;
          ui = true;
          extra = true;

          lspDebugMode = false;
          themer = true;
          colorscheme = "catppuccin";

          # Pass stylix colors to Lua
          colors = stylixColors;
        };
        extra = {
          nixdExtras = {
            inherit (inputs) nixpkgs;
            flake-path = inputs.self;
          };
        };
      };
  };
}

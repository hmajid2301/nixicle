{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (inputs.nixCats) utils;
in
{
  # XDG configuration files
  xdg.configFile."nvim/queries/go/injections.scm".text =
    builtins.readFile ./lua/config/syntax/go.scm;
  xdg.configFile."nvim/queries/templ/injections.scm".text =
    builtins.readFile ./lua/config/syntax/html.scm;
  xdg.configFile."nvim/doc/nixicle.txt".text =
    builtins.readFile ./doc/nixicle.txt;

  # OXY2DEV fancy scripts
  xdg.configFile."nvim/lua/scripts/lsp_hover.lua".source =
    "${inputs.oxy2dev-nvim-scripts}/lua/scripts/lsp_hover.lua";
  xdg.configFile."nvim/lua/scripts/diagnostics.lua".source =
    "${inputs.oxy2dev-nvim-scripts}/lua/scripts/diagnostics.lua";

  # NixCats configuration
  nixCats = {
    enable = true;
    nixpkgs_version = inputs.nixpkgs;
    addOverlays = [ (utils.standardPluginOverlay inputs) ];
    packageNames = [
      "regularCats"
      "nixCats"
    ];

    luaPath = "${./.}";
  };
}

# Neovim Configuration Module
#
# This module provides a comprehensive Neovim setup using nixCats:
# - LSP support for multiple languages (Go, TypeScript, Python, Nix, etc.)
# - Plugin management with lazy loading
# - Debugging support (DAP)
# - Testing integration (Neotest)
# - Git integration
# - AI assistance (Sidekick)
#
# The module has been split into focused files for better maintainability:
# - config.nix: XDG configuration files and nixCats basic setup
# - lsp-and-tools.nix: LSP servers and runtime dependencies for each language
# - plugins.nix: Startup and optional plugins with their dependencies
# - package-definitions.nix: Package configurations (nixCats and regularCats)

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (inputs.nixCats) utils;

  # Import the sub-modules
  configModule = import ./config.nix { inherit config lib pkgs inputs; };
  lspAndToolsModule = import ./lsp-and-tools.nix { inherit pkgs; };
  pluginsModule = import ./plugins.nix;
  packageDefinitionsModule = import ./package-definitions.nix { inherit config inputs; };
in
{
  imports = [
    inputs.nixCats.homeModule
  ];

  config = {
    nix.settings = {
      extra-substituters = [ "https://nvim-treesitter-main.cachix.org" ];
      extra-trusted-public-keys = [ "nvim-treesitter-main.cachix.org-1:cbwE6blfW5+BkXXyeAXoVSu1gliqPLHo2m98E4hWfZQ=" ];
    };

    xdg = configModule.xdg;

    nixCats = configModule.nixCats // {
      # Category definitions with all the plugin and LSP configurations
      categoryDefinitions.replace =
        {
          pkgs,
          settings,
          categories,
          extra,
          name,
          mkNvimPlugin,
          ...
        }@packageDef:
        (lspAndToolsModule // (pluginsModule { inherit pkgs categories; }));

      # Package definitions
      packageDefinitions = packageDefinitionsModule.packageDefinitions;
    };
  };
}

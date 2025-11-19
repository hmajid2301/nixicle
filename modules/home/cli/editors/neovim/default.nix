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

{delib, inputs, ...}:
delib.module {
  name = "cli-editors-neovim";

  imports = [
    inputs.nixCats.homeModule
  ];

  home.always = {config, lib, pkgs, inputs, ...}:
  let
    inherit (inputs.nixCats) utils;

    # Import the sub-modules
    configModule = import ./config.nix.helper { inherit config lib pkgs inputs; };
    lspAndToolsModule = import ./lsp-and-tools.nix.helper { inherit pkgs; };
    pluginsModule = import ./plugins.nix.helper;
    packageDefinitionsModule = import ./package-definitions.nix.helper { inherit config inputs; };
  in
  {
    # Include XDG config and basic nixCats setup
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

inputs:
{
  config,
  wlib,
  lib,
  pkgs,
  ...
}:
{
  _file = ./default.nix;
  key = ./default.nix;
  config._module.args.inputs = inputs;
  imports = [
    wlib.wrapperModules.neovim
    ./nvim-lib.nix
    ./specs.nix
  ];

  config.package = pkgs.neovim-unwrapped;

  # aliases: vi and vim point to the nvim binary
  config.settings.aliases = [ "vi" "vim" ];

  # Config directory: use the wrapped store path by default.
  # Set unwrapped_mode = true to use the live filesystem path (like old regularCats).
  options.settings.unwrapped_mode = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };
  options.settings.wrapped_config = lib.mkOption {
    type = lib.types.either wlib.types.stringable lib.types.luaInline;
    default = ./..;
  };
  # Live filesystem path for editing without rebuilds.
  # Hardcoded because toString ./.. gives a Nix store copy, not the live path.
  options.settings.unwrapped_config = lib.mkOption {
    type = lib.types.either wlib.types.stringable lib.types.luaInline;
    default = lib.generators.mkLuaInline "vim.uv.os_homedir() .. '/nixicle/modules/aspects/neovim'";
  };
  config.settings.config_directory =
    if config.settings.unwrapped_mode
    then config.settings.unwrapped_config
    else config.settings.wrapped_config;
}

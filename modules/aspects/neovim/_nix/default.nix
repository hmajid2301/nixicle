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
  config.settings.aliases = [
    "vi"
    "vim"
  ];

  options.settings.unwrapped_mode = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };
  options.settings.wrapped_config = lib.mkOption {
    type = lib.types.either wlib.types.stringable lib.types.luaInline;
    default = ./..;
  };
  # Hardcoded: toString ./.. gives a store copy, not the live filesystem path.
  options.settings.unwrapped_config = lib.mkOption {
    type = lib.types.either wlib.types.stringable lib.types.luaInline;
    default = lib.generators.mkLuaInline "vim.uv.os_homedir() .. '/nixicle/modules/aspects/neovim'";
  };
  config.settings.config_directory =
    if config.settings.unwrapped_mode then
      config.settings.unwrapped_config
    else
      config.settings.wrapped_config;
}

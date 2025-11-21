{
  pkgs,
  config,
  lib,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;

let
  cfg = config.hardware.zsa-keyboard;
in
{
  options.hardware.zsa-keyboard = with types; {
    enable = mkBoolOpt false "Whether or not to enable ZSA keyboard tools (Keymapp)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      keymapp # ZSA keyboard configuration tool (for Moonlander, Voyager, etc)
    ];
  };
}

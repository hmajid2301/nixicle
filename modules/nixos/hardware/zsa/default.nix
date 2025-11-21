{
  options,
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
  cfg = config.hardware.zsa;
in {
  options.hardware.zsa = with types; {
    enable = mkBoolOpt false "Enable ZSA Keyboard";
  };

  config = mkIf cfg.enable {
    hardware.keyboard.zsa.enable = true;
  };
}

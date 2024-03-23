{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.hardware.zsa;
in {
  options.hardware.zsa = with types; {
    enable = mkBoolOpt false "Enable ZSA Keyboard";
  };

  config = mkIf cfg.enable {
    hardware.keyboard.zsa.enable = true;
  };
}

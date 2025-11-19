{delib, ...}:
delib.module {
  name = "hardware-zsa-keyboard";

  options.hardware.zsa-keyboard = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.hardware.zsa-keyboard;
  in
  mkIf cfg.enable {
    home.packages = with pkgs; [
      keymapp # ZSA keyboard configuration tool (for Moonlander, Voyager, etc)
    ];
  };
}

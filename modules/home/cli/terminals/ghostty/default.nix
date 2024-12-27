{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
with lib; let
  cfg = config.cli.terminals.ghostty;
in {
  options.cli.terminals.ghostty = {
    enable = mkEnableOption "enable ghostty terminal emulator";
  };

  config = mkIf cfg.enable {
    xdg.configFile."ghostty/config".text = ''
      theme = catppuccin-mocha
      font-family = "MonoLisa Nerd Font"
      command = fish
      gtk-titlebar = false
      font-size = 14
      window-padding-x = 6
      window-padding-y = 6
      copy-on-select = clipboard
      cursor-style = block
    '';

    home.packages = with inputs; [
      ghostty.packages.${pkgs.system}.default
    ];
  };
}

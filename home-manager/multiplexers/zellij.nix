{ lib, config, ... }:
with lib;
let
  cfg = config.modules.multiplexers.zellij;
in
{
  options.modules.multiplexers.zellij = {
    enable = mkEnableOption "enable zellij multiplexer";
  };

  config = mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      settings = {
        # TODO: nix-colors: https://github.com/Zaechus/nixos-config/blob/e60d0a626d93671253c8ca9bc2730f4d11ac6861/themes/nord/default.nix#L77-L87
        theme = "catppuccin-mocha";
      };
    };
  };
}

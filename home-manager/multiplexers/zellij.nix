{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.modules.multiplexers.zellij;
  inherit (config.colorscheme) colors;
in {
  options.modules.multiplexers.zellij = {
    enable = mkEnableOption "enable zellij multiplexer";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.tmate
      inputs.zjstatus.packages.${pkgs.system}.default
    ];
    # xdg.configFile = {
    #   "zellij/layouts/default.kdl".text = ''
    #     layout {
    #       pane size=1 borderless=true {
    #         plugin location="file:${inputs.zjstatus.packages.${pkgs.system}.default}/bin/zjstatus.wasm" {
    #           format_left "{mode}#[bg=${colors.base04}] {tabs}"
    #           format_space "#[bg=${colors.base04}]"
    #
    #           mode_normal "#[bg=${colors.base02},fg=${colors.base07},bold] {name} "
    #           mode_tab "#[bg=${colors.base04},fg=${colors.base00},bold] {name} "
    #
    #           tab_normal "#[bg=${colors.base02},fg=${colors.base0C}] {name} "
    #           tab_active "#[bg=${colors.base03},fg=${colors.base00}] {name} "
    #         }
    #       }
    #       pane split_direction="vertical" {
    #         pane
    #       }
    #     }
    #   '';
    # };

    programs.zellij = {
      enable = true;
      settings = {
        pane_frames = false;
        default_layout = "compact";
        # TODO: nix-colors: https://github.com/Zaechus/nixos-config/blob/e60d0a626d93671253c8ca9bc2730f4d11ac6861/themes/nord/default.nix#L77-L87
        theme = "catppuccin-mocha";
      };
    };
  };
}

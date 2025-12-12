{
  config,
  lib,
  inputs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.multiplexers.zellij.plugins.pane-tracker;
in
{
  options.cli.multiplexers.zellij.plugins.pane-tracker = {
    enable = mkBoolOpt true "Enable zellij pane-tracker plugin";
  };

  config = mkIf cfg.enable {
    # Add pane-tracker to zellij config
    xdg.configFile."zellij/plugins/pane-tracker.wasm" = {
      source = "${inputs.zellij-pane-tracker}/target/wasm32-wasip1/release/pane-tracker.wasm";
    };
  };
}

{delib, ...}:
delib.module {
  name = "cli-tools-nix-index";

  options.cli.tools.nix-index = with delib; {
    enable = boolOption false;
  };

  # Note: nix-index-database requires home module import but causes evaluation issues with denix
  # TODO: Find a way to properly import nix-index-database.hmModules.nix-index
  home.always = {config, lib, inputs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.nix-index;
  in
  mkIf cfg.enable {
    programs.nix-index = {
      enable = true;
      enableBashIntegration = true;
    };
    # Disabled: requires nix-index-database home module which conflicts with denix evaluation
    # programs.nix-index-database.comma.enable = true;
  };
}

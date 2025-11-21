{
  lib,
  config,
  inputs,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;
 let
  cfg = config.cli.tools.nix-index;
in {
  options.cli.tools.nix-index = with types; {
    enable = mkBoolOpt false "Whether or not to nix index";
  };

  # nix-index-database is already imported globally in commonHomeModules

  config = mkIf cfg.enable {
    programs.nix-index = {
      enable = true;
      enableBashIntegration = true;
    };
    programs.nix-index-database.comma.enable = true;
  };
}

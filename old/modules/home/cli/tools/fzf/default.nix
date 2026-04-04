{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.tools.fzf;
in
{
  options.cli.tools.fzf = with types; {
    enable = mkBoolOpt false "Whether or not to enable fzf";
  };

  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableFishIntegration = false;
      colors =
        with config.lib.stylix.colors.withHashtag;
        mkForce {
          "bg" = base00;
          "bg+" = base02;
          "fg" = base05;
          "fg+" = base05;
          "header" = base0E;
          "hl" = base08;
          "hl+" = base08;
          "info" = base0A;
          "marker" = base06;
          "pointer" = base06;
          "prompt" = base0E;
          "spinner" = base06;
        };
    };
  };
}

{
  lib,
  config,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;
 let
  cfg = config.cli.tools.htop;
in {
  options.cli.tools.htop = with types; {
    enable = mkBoolOpt false "Whether or not to enable htop";
  };

  config = mkIf cfg.enable {
    programs.htop = {
      enable = true;
      settings = {
        hide_userland_threads = 1;
        highlight_base_name = 1;
        show_cpu_temperature = 1;
        show_program_path = 0;
      };
    };
  };
}

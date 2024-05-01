{
  lib,
  config,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.programs.htop;
in {
  options.cli.programs.htop = with types; {
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

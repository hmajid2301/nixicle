{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.desktops.addons.cava;
  inherit (config.lib.stylix) colors;
in
{
  options.desktops.addons.cava = with types; {
    enable = mkBoolOpt false "Enable cava audio visualizer";

    bars = mkOption {
      type = int;
      default = 0;
      description = "Number of bars (0 = auto-calculate based on terminal width)";
    };

    framerate = mkOption {
      type = int;
      default = 60;
      description = "Framerate for the visualizer (higher = smoother, more CPU)";
    };

    stereo = mkOption {
      type = bool;
      default = false;
      description = "Enable stereo mode (split left/right channels)";
    };

    sensitivity = mkOption {
      type = int;
      default = 100;
      description = "Sensitivity (0-255, higher = more responsive)";
    };
  };

  config = mkIf cfg.enable {
    programs.cava = {
      enable = true;
      settings = {
        general = {
          bars = cfg.bars;
          framerate = cfg.framerate;
          stereo = cfg.stereo;
          sensitivity = cfg.sensitivity;
          autosens = 1;
          lower_cutoff_freq = 50;
          higher_cutoff_freq = 10000;
        };

        input = {
          method = "pipewire";
          source = "auto";
        };

        output = {
          method = "ncurses";
          orientation = "bottom";
          channels = "stereo";
        };

        color = mkIf (colors != null) {
          gradient = 1;
          gradient_count = 6;
          gradient_color_1 = "'#${colors.base08}'";
          gradient_color_2 = "'#${colors.base09}'";
          gradient_color_3 = "'#${colors.base0A}'";
          gradient_color_4 = "'#${colors.base0B}'";
          gradient_color_5 = "'#${colors.base0C}'";
          gradient_color_6 = "'#${colors.base0D}'";

        };

        smoothing = {
          monstercat = 1;
          waves = 0;
          gravity = 100;
          ignore = 0;
        };
      };
    };
  };
}

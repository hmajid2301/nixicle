{ lib, ... }:
{
  options.nixicle.desktop.shell = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether a desktop shell should be integrated into the shared Niri session.";
    };

    startup.args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Arguments used to launch the configured desktop shell from Niri.";
    };

    lockSuspend.args = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      description = "Arguments used by laptop lid-close handling to lock and suspend through the active shell.";
    };
  };
}

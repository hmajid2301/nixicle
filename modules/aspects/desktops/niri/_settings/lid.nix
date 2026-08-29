{
  pkgs,
  config,
  hostIsLaptop,
  lib,
  ...
}:
let
  shell = config.nixicle.desktop.shell;
  lidGuard = import ../_lid-guard.nix {
    inherit pkgs lib;
    lockSuspendArgs = shell.lockSuspend.args;
  };
in
if hostIsLaptop && shell.lockSuspend.args != null then
  {
    _children = lib.mkAfter [
      {
        "switch-events" = {
          _children = [
            {
              "lid-close".spawn = [ "${lidGuard}" ];
            }
          ];
        };
      }
    ];
  }
else
  {
  }

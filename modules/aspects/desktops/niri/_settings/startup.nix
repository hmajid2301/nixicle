{ lib, config, ... }:
let
  startup = config.nixicle.desktop.niri.startup;
  shell = config.nixicle.desktop.shell;
in
{
  _children = lib.mkAfter (
    map (args: { "spawn-at-startup"._args = args; }) (
      [ startup.xwaylandArgs ] ++ startup.extraCommands ++ lib.optional shell.enable shell.startup.args
    )
  );
}

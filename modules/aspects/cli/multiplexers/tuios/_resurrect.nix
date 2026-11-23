{
  lib,
  pkgs,
  src,
}:
let
  toml = pkgs.formats.toml { };
  upstream = builtins.fromTOML (builtins.readFile "${src}/herdr-plugin.toml");
  pinCommand =
    entry:
    entry
    // {
      command = map (
        arg:
        if arg == "node" then
          lib.getExe pkgs.nodejs
        else if arg == "bash" then
          lib.getExe pkgs.bash
        else
          arg
      ) entry.command;
    };
  autosave = pkgs.writeShellScript "tuios-resurrect-autosave" ''
    cd "$HERDR_PLUGIN_ROOT"
    while true; do
      ${lib.getExe pkgs.nodejs} bin/on-event.js
      ${lib.getExe' pkgs.coreutils "sleep"} 30
    done
  '';
  manifest = toml.generate "herdr-plugin.toml" (
    upstream
    // {
      actions = map pinCommand upstream.actions;
      events = map pinCommand upstream.events;
      panes = map pinCommand upstream.panes;
      startup = [
        {
          command = [
            (lib.getExe pkgs.bash)
            autosave
          ];
        }
      ];
    }
  );
  native = toml.generate "tuios-plugin.toml" {
    schema = 1;
    inherit (upstream) id;
    herdr.manifest = "herdr-plugin.toml";
    permissions.grants = [ "admin" ];
  };
in
pkgs.runCommand "tuios-plugin-herdr-resurrect" { } ''
  mkdir -p "$out"
  cp -r ${src}/. "$out/"
  chmod -R u+w "$out"
  ${lib.getExe pkgs.patch} -d "$out" -p1 < ${./_resurrect-npm.patch}
  cp ${manifest} "$out/herdr-plugin.toml"
  cp ${native} "$out/tuios-plugin.toml"
''

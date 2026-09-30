# Home-manager port of nirinit's upstream NixOS module, so session restore
# also works on non-NixOS homes (e.g. the Ubuntu dell host) that share this
# aspect. Mirrors services.nirinit from github:amaanq/nirinit.
{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  nirinit = inputs.nirinit.packages.${pkgs.stdenv.hostPlatform.system}.nirinit;

  # mirrors upstream `services.nirinit.settings` defaults
  settings = {
    skip.apps = [ "steam" ];
    launch = {
      "com.mitchellh.ghostty" = "ghostty";
      "org.gnome.Nautilus" = "nautilus";
    };
  };

  configFile = (pkgs.formats.toml { }).generate "nirinit-config.toml" settings;
in
{
  systemd.user.services.nirinit = {
    Unit = {
      Description = "Nirinit session manager";
      Wants = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe nirinit} --config ${configFile}";
      Restart = "always";
      PrivateTmp = true;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}

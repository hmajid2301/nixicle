{
  pkgs,
  config,
  lib,
  ...
}:
let
  noctaliaShimmed = config.lib.pamShim.replacePam config.programs.noctalia.package;
  noctaliaNixGL = pkgs.writeShellScript "noctalia-nixgl" ''
    export PATH="${config.home.profileDirectory}/bin:/run/wrappers/bin:/usr/bin:/bin"
    exec ${config.lib.nixGL.wrap noctaliaShimmed}/bin/noctalia "$@"
  '';
in
{
  nixicle.desktop.niri.startup.xwaylandArgs = [
    "env"
    "-u"
    "LD_LIBRARY_PATH"
    "-u"
    "__EGL_VENDOR_LIBRARY_FILENAMES"
    "-u"
    "LIBGL_DRIVERS_PATH"
    "-u"
    "GBM_BACKENDS_PATH"
    "xwayland-satellite"
  ];

  nixicle.desktop.shell = {
    startup.args = [ "${noctaliaNixGL}" ];
    lockSuspend.args = [
      "${noctaliaNixGL}"
      "msg"
      "session"
      "lock-and-suspend"
    ];
  };

  programs.noctalia.systemd.enable = lib.mkForce false;
}

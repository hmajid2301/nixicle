{ pkgs, config, inputs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  home.packages =
    with pkgs;
    [
      cliphist
      wl-clipboard
      wdisplays
    ]
    ++ (with inputs.nfsm.packages.${pkgs.stdenv.hostPlatform.system}; [
      nfsm
      nfsm-cli
    ]);

  xdg.configFile = {
    "noctalia/plugins/display-config".source = "${inputs.noctalia-plugins}/display-config";
    "noctalia/plugins/rbw-provider".source = "${inputs.noctalia-plugins}/rbw-provider";
  };

  systemd.user.services.lock-before-sleep = {
    Unit = {
      Description = "Lock noctalia before sleep";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.writeShellScript "lock-before-sleep" ''
        exec ${pkgs.systemd}/bin/systemd-inhibit \
          --what=sleep --mode=delay --who=lock-before-sleep --why=\"Lock screen before sleep\" \
          ${pkgs.dbus}/bin/dbus-monitor --system \
            \"type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'\" \
          | while read -r line; do
              case \"$line\" in
                *\"boolean true\"*)
                  ${config.programs.noctalia-shell.package}/bin/noctalia-shell ipc call lockScreen lock \
                    || ${pkgs.systemd}/bin/loginctl lock-session
                  sleep 1
                  ;;
              esac
            done
      ''}";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  wayland.windowManager.niri = {
    enable = true;
    package = pkgs.niri;
    xwaylandSatellitePackage = pkgs.xwayland-satellite;
    extraConfig = import ./_extra-config.nix { };
  };
}

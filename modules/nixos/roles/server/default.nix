{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.roles.server;
in {
  options.roles.server = {
    enable = mkEnableOption "Enable server configuration";
  };

  config = mkIf cfg.enable {
    roles = {
      common.enable = true;
    };

    services = {
      nixicle.avahi.enable = true;
      nixicle.tailscale.enable = true;
      getty.autologinUser = "nixos";
    };

    systemd.services.NetworkManager-wait-online.enable = false;
    systemd.network.wait-online.enable = false;
    systemd.tmpfiles.rules = [
      "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
    ];

    services.openiscsi = {
      enable = true;
      name = "<some-name>";
    };

    environment =
      {
        systemPackages = [
          pkgs.nfs-utils
          pkgs.openiscsi
          pkgs.dnsutils
          pkgs.tmux
        ];
        # Print the URL instead on servers
        variables.BROWSER = "echo";
      }
      // lib.optionalAttrs (lib.versionAtLeast (lib.versions.majorMinor lib.version) "24.05") {
        # Don't install the /lib/ld-linux.so.2 and /lib64/ld-linux-x86-64.so.2
        # stubs. Server users should know what they are doing.
        stub-ld.enable = lib.mkDefault false;
      };

    security.sudo.wheelNeedsPassword = false;
    # Only allow members of the wheel group to execute sudo by setting the executable’s permissions accordingly. This prevents users that are not members of wheel from exploiting vulnerabilities in sudo such as CVE-2021-3156.
    security.sudo.execWheelOnly = true;
    # Don't lecture the user. Less mutable state.
    security.sudo.extraConfig = ''
      Defaults lecture = never
    '';

    # Notice this also disables --help for some commands such es nixos-rebuild
    documentation.enable = lib.mkDefault false;
    documentation.info.enable = lib.mkDefault false;
    documentation.man.enable = lib.mkDefault false;
    documentation.nixos.enable = lib.mkDefault false;

    # No need for fonts on a server
    fonts.fontconfig.enable = lib.mkDefault false;

    programs.vim.defaultEditor = lib.mkDefault true;

    # If the user is in @wheel they are truste  # No need for sound on a server
    sound.enable = false;

    # UTC everywhere!
    time.timeZone = lib.mkDefault "UTC";

    # No mutable users by default
    users.mutableUsers = false;

    systemd = {
      # Given that our systems are headless, emergency mode is useless.
      # We prefer the system to attempt to continue booting so
      # that we can hopefully still access it remotely.
      enableEmergencyMode = false;

      # For more detail, see:
      #   https://0pointer.de/blog/projects/watchdog.html
      watchdog = {
        # systemd will send a signal to the hardware watchdog at half
        # the interval defined here, so every 10s.
        # If the hardware watchdog does not get a signal for 20s,
        # it will forcefully reboot the system.
        runtimeTime = "20s";
        # Forcefully reboot if the final stage of the reboot
        # hangs without progress for more than 30s.
        # For more info, see:
        #   https://utcc.utoronto.ca/~cks/space/blog/linux/SystemdShutdownWatchdog
        rebootTime = "30s";
      };
    };

    # use TCP BBR has significantly increased throughput and reduced latency for connections
    boot.kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };

    user = {
      name = "nixos";
      initialPassword = "1";
    };
  };
}

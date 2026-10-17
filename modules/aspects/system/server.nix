_: {
  den.aspects.server = {
    nixos =
      { lib, pkgs, ... }:
      {
        # Automatic garbage collection so server generations don't accumulate.
        # Uses mkDefault so hosts (e.g. rpi) can override retention per-host.
        nix.gc = {
          automatic = lib.mkDefault true;
          dates = lib.mkDefault "daily";
          options = lib.mkDefault "--delete-older-than 7d";
        };
        nix.optimise.automatic = lib.mkDefault true;

        systemd = {
          services.tailscaled.restartIfChanged = false;
          services.nix-prune-generations = {
            description = "Prune old system generations, keeping the most recent";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.nix}/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations +10";
            };
          };
          timers.nix-prune-generations = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = lib.mkDefault "*-*-* 23:30:00";
              Persistent = true;
            };
          };
        };
      };

    homeManager =
      { lib, ... }:
      {
        programs.zellij = lib.mkForce {
          enable = true;
          settings = {
            theme = "stylix";
            default_layout = "compact";
            pane_frames = false;
            simplified_ui = true;
            copy_on_select = true;
            show_startup_tips = false;
          };
        };
      };
  };
}

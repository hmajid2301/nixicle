_: {
  den.aspects.server = {
    nixos =
      { lib, ... }:
      {
        # Automatic garbage collection so server generations don't accumulate.
        # Uses mkDefault so hosts (e.g. rpi) can override retention per-host.
        nix.gc = {
          automatic = lib.mkDefault true;
          dates = lib.mkDefault "weekly";
          options = lib.mkDefault "--delete-older-than 30d";
        };
        nix.optimise.automatic = lib.mkDefault true;
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

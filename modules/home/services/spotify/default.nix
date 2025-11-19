{delib, ...}:
delib.module {
  name = "services-spotify";

  options.services.spotify = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  let
    cfg = config.services.spotify;
  in
  mkIf cfg.enable {
    home.packages = with pkgs; [
      # spotify-tui
    ];

    # services.spotifyd = {
    #   enable = true;
    # };
  };
}

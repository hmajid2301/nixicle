{ lib, config, ... }:

with lib;
let
  cfg = config.modules.browsers.firefox;
in
{
  options.modules.browsers.firefox = {
    enable = mkEnableOption "enable firefox browser";
  };

  config = mkIf cfg.enable {

    # home = {
    #   persistence = {
    #     # Not persisting is safer
    #     "/persist/home/misterio".directories = [ ".mozilla/firefox" ];
    #   };
    # };

    programs.firefox = {
      enable = true;
      profiles.default = {
        name = "Default";
      };

      # userChrome = builtins.readFile (builtins.fetchurl {
      #   url = "https://raw.githubcontent.com/andreasgrafen/cascade/tree/2f70e8619ce5c721fe9c0736b25c5a79938f1215/chrome";
      #   sha256 = "";
      # });
      #extensions = nur.repos.rycee.firefox-addons; [
      #  bitwarden
      #  facebook-container
      #  duckduckgo-privacy-essentials
      #  reddit-enhancement-suite
      #  tridactyl
      #  private-relay
      #  privacy-badger
      #  return-youtube-dislike
      #  stylus
      #  ublock-origin
      #];
    };
  };
}

{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.user;
in {
  options.user = with types; {
    name = mkOpt str "haseeb" "The name of the user's account";
    initialPassword =
      mkOpt str "1"
      "The initial password to use";
    extraGroups = mkOpt (listOf str) [] "Groups for the user to be assigned.";
    extraOptions =
      mkOpt attrs {}
      "Extra options passed to users.users.<name>";
  };

  config = {
    users.users.haseeb =
      {
        isNormalUser = true;
        inherit (cfg) name initialPassword;
        home = "/home/haseeb";
        group = "users";

        extraGroups =
          ["wheel" "audio" "sound" "video" "networkmanager" "input" "tty" "podman"]
          ++ cfg.extraGroups;
      }
      // cfg.extraOptions;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}

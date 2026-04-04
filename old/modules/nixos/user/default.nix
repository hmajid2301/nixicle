{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.user;
in
{
  options.user = with types; {
    name = mkOpt str "haseeb" "The name of the user's account";
    passwordSecretFile = mkOpt (nullOr path) null "Path to sops secret file containing hashed password";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions = mkOpt attrs { } "Extra options passed to users.users.<name>";
  };

  config = {
    users.mutableUsers = false;
    users.users.${cfg.name} = {
      isNormalUser = true;
      inherit (cfg) name;
      hashedPasswordFile = cfg.passwordSecretFile;
      home = "/home/${cfg.name}";
      group = "users";

      extraGroups = [
        "wheel"
        "audio"
        "sound"
        "video"
        "networkmanager"
        "input"
        "tty"
        "docker"
        "kvm"
        "libvirtd"
      ]
      ++ cfg.extraGroups;
    }
    // cfg.extraOptions;

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };
}

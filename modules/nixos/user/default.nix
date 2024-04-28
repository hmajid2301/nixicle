{
  config,
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
    users.users.root.initialHashedPassword = lib.mkForce "$6$OjyHeF4q55WkXchz$mYFo7PbEsn/mhr9HO5Kjgj48RuVEQabMDpd5wkp2sVoXFUJatZKcYv2Lw/NmPSKTkHFarGBf540XD5lW/0iqj.";
    users.mutableUsers = false;
    users.users.haseeb =
      {
        isNormalUser = true;
        inherit (cfg) name;
        hashedPassword = "$6$y5esF/udtz4xFe7n$n725gxaOsIWfxShrM06TkWD7MpTd9Ai6x25IRmcrIvB4FxOfhyIdJx5W967S3uISn2iZdEKpWFryd3dAW6KN51";
        home = "/home/haseeb";
        group = "users";

        # TODO: set in modules
        extraGroups =
          [
            "wheel"
            "audio"
            "sound"
            "video"
            "networkmanager"
            "input"
            "tty"
            "podman"
            "kvm"
            "libvirtd"
            "qemu-libvirtd"
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

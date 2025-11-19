{delib, ...}:
delib.module {
  name = "user";

  options = with delib; {};

  nixos.always = {myconfig, ...}: {
    users.users.${myconfig.constants.username} = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager" "audio" "video" "docker" "libvirtd"];
      initialPassword = "nixos";
    };
  };

  darwin.always = {myconfig, ...}: {
    users.users.${myconfig.constants.username} = {
      home = "/Users/${myconfig.constants.username}";
    };
  };
}

{delib, ...}:
delib.module {
  name = "home";

  options = with delib; {};

  home.always = {
    myconfig,
    lib,
    ...
  }: {
    home = {
      username = myconfig.constants.username;
      homeDirectory =
        if myconfig.host.darwin
        then "/Users/${myconfig.constants.username}"
        else "/home/${myconfig.constants.username}";
    };
  };
}

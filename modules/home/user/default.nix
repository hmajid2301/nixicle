{delib, ...}:
delib.module {
  name = "user";

  options.nixicle.user = with delib; {
    enable = boolOption false;
    home = noDefault (nullOrOption strOption);
    name = noDefault (nullOrOption strOption);
  };

  home.always = {config, lib, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.nixicle.user;
  in
  mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.name != null;
          message = "nixicle.user.name must be set";
        }
      ];

      home = {
        homeDirectory = mkDefault (if cfg.home != null then cfg.home else "/home/${cfg.name}");
        username = mkDefault cfg.name;
      };
    }
  ]);
}

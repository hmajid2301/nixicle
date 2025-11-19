{delib, ...}:
delib.module {
  name = "services-syncthing";

  options.services.nixicle.syncthing = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, ...}:
  with lib;
  let
    cfg = config.services.nixicle.syncthing;
  in
  mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      tray.enable = true;
      extraOptions = ["--gui-address=127.0.0.1:8384"];
    };
  };
}

{delib, ...}:
delib.module {
  name = "roles-video";

  options.roles.video = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, inputs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.roles.video;
  in
  mkIf cfg.enable {
    xdg.configFile."obs-studio/themes".source =
      "${inputs.catppuccin-obs}/themes";

    programs.obs-studio = { enable = true; };

    home.packages = with pkgs; [
      audacity
      kdePackages.kdenlive
      davinci-resolve-studio
    ];
  };
}

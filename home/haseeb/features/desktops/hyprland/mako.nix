{config, pkgs, ...}: {

  services.mako = {
    enable = true;
    defaultTimeout = 5000;
    backgroundColor="#${config.colorscheme.colors.base00}";
    textColor="#${config.colorscheme.colors.base05}";
    borderColor="#${config.colorscheme.colors.base0D}";
    progressColor="over #${config.colorscheme.colors.base02}";
    extraConfig = ''
      [urgency=high]
      border-color=#${config.colorscheme.colors.base09}
    '';
  };

  home.packages = with pkgs; [
    libnotify
  ];
}

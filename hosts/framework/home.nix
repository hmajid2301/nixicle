{ inputs
, lib
, config
, ...
}: {
  imports = [
    ./programs.nix
  ];

  my.settings = {
    wallpaper = "../../home-manager/wallpapers/rainbow-nix.jpg";
    host = "framework";
    default = {
      shell = "fish";
      terminal = "foot";
      browser = "firefox";
      editor = "nvim";
    };
  };

  colorscheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;

  home = {
    username = lib.mkDefault "haseeb";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "23.05";

    #persistence = {
    #  "/persist/home/haseeb" = {
    #    directories = [
    #      "Documents"
    #      "Downloads"
    #      "Pictures"
    #      "Videos"
    #      "Games"
    #      "projects"
    #      "dotfiles"
    #      "go"
    #      ".local"
    #      ".tmux"
    #      ".ssh"
    #      ".gnupg"
    #      ".config/gtk"
    #    ];
    #    allowOther = true;
    #  };
    #};
  };
}

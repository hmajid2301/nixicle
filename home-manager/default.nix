{ inputs
, lib
, pkgs
, config
, outputs
, ...
}: {
  imports =
    [
      inputs.nix-colors.homeManagerModule
      inputs.nixvim.homeManagerModules.nixvim
      inputs.nur.hmModules.nur
      inputs.impermanence.nixosModules.home-manager.impermanence

      ./fonts.nix
      ./programs

      ./browsers/firefox.nix

      ./editors/nvim

      ./multiplexers/tmux.nix
      ./multiplexers/zellij.nix

      ./shells/fish.nix
      ./shells/zsh.nix

      ./terminals/alacritty.nix
      ./terminals/foot.nix
    ]
    ++ builtins.attrValues outputs.homeManagerModules;

  systemd.user.startServices = "sd-switch";

  programs = {
    home-manager.enable = true;
  };

  home.sessionVariables.EDITOR = config.my.settings.default.editor;

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays ++ [
      inputs.nixneovimplugins.overlays.default
      inputs.nur.overlay
    ];

    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      substituters = [
        "https://majiy00-nix-binary-cache.fly.dev/prod"
        "https://cache.nixos.org"
      ];

      trusted-public-keys = [
        "prod:fjP15qp9O3/x2WTb1LiQ2bhjxkBBip3uhjlDyqywz3I="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      warn-dirty = false;
      netrc-file = "$HOME/.config/nix/netrc";
    };
  };
}

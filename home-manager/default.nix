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
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      warn-dirty = false;
    };
  };
}

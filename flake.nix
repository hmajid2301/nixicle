{
  description = "Haseeb's Nix/NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko.url = "github:nix-community/disko";
    hardware.url = "github:nixos/nixos-hardware";
    sops-nix.url = "github:mic92/sops-nix";

    impermanence.url = "github:nix-community/impermanence";
    lanzaboote.url = "github:nix-community/lanzaboote";

    nixgl.url = "github:nix-community/nixGL";
    nix-colors.url = "github:misterio77/nix-colors";
    nix-ld.url = "github:Mic92/nix-ld";
    nix-index-database.url = "github:nix-community/nix-index-database";

    comma = {
      url = "github:nix-community/comma";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hypr-contrib = {
      url = "github:hyprwm/Hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprcursor = {
      url = "github:hyprwm/Hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hypridle = {
      url = "github:hyprwm/Hypridle";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprlock = {
      url = "github:hyprwm/Hyprlock";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprpaper = {
      url = "github:hyprwm/hyprpaper";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyprland = {
      url = "github:hyprland-community/pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-git.url = "github:hyprwm/hyprland";
    hyprland-xdph-git.url = "github:hyprwm/xdg-desktop-portal-hyprland";
    hyprland-protocols-git.url = "github:hyprwm/xdg-desktop-portal-hyprland";
    hyprland-nix.url = "github:spikespaz/hyprland-nix";
    hyprland-nix.inputs = {
      hyprland.follows = "hyprland-git";
      hyprland-xdph.follows = "hyprland-xdph-git";
      hyprland-protocols.follows = "hyprland-protocols-git";
    };

    nixvim = {
      url = "github:pta2002/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    waybar.url = "github:Alexays/Waybar?rev=32eac3ccb738691974121b77b4af0c47d1cbe524";

    firefox-gnome-theme = {
      url = "github:rafaelmardojai/firefox-gnome-theme";
      flake = false;
    };

    copilotchat-nvim = {
      url = "github:copilotc-nvim/copilotchat.nvim";
      flake = false;
    };
    neorg-templates = {
      url = "github:pysan3/neorg-templates";
      flake = false;
    };
    arrow-nvim = {
      url = "github:otavioschwanck/arrow.nvim";
      flake = false;
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;
      snowfall = {
        metadata = "nixicle";
        namespace = "nixicle";
        meta = {
          name = "nixicle";
          title = "Haseeb's Nix Flake";
        };
      };

      channels-config = {
        allowUnfree = true;
      };

      systems.modules.nixos = with inputs; [
        home-manager.nixosModules.home-manager
        disko.nixosModules.disko
        lanzaboote.nixosModules.lanzaboote
        impermanence.nixosModules.impermanence
        sops-nix.nixosModules.sops
        nix-ld.nixosModules.nix-ld
      ];

      systems.hosts.framework.modules = with inputs; [
        hardware.nixosModules.framework-13-7040-amd
      ];

      # TODO: move to relevant files
      # homes.modules = with inputs; [
      #   impermanence.nixosModules.home-manager.impermanence
      # ];

      overlays = with inputs; [
        nixgl.overlay
      ];
    };
}

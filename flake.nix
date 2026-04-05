{
  description = "Haseeb's Nix/NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
    };

    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";
    lanzaboote.url = "github:nix-community/lanzaboote";

    nixgl.url = "github:nix-community/nixGL";
    nix-index-database.url = "github:nix-community/nix-index-database";
    den.url = "github:vic/den";
    flake-file.url = "github:vic/flake-file";

    # PAM shim for non-NixOS systems
    # Using 'next' branch for full libpam.so.0 API coverage
    pam-shim = {
      url = "github:Cu3PO42/pam_shim/next";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    nixos-anywhere = {
      url = "github:numtide/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    comma = {
      url = "github:nix-community/comma";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland

    hypr-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprcursor = {
      url = "github:hyprwm/Hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Niri

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nfsm = {
      url = "github:gvolpe/nfsm";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Quickshell

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Services

    tangled = {
      url = "git+https://tangled.sh/@tangled.sh/core";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixery = {
      url = "github:tazjin/nixery";
      flake = false;
    };

    banterbus = {
      url = "gitlab:hmajid2301/banterbus";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    goroutinely = {
      url = "gitlab:hmajid2301/goroutinely/feat/move-to-internal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homelab

    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    authentik-nix = {
      url = "github:nix-community/authentik-nix";
    };

    # Styling

    catppuccin-obs = {
      url = "github:catppuccin/obs";
      flake = false;
    };

    stylix.url = "github:danth/stylix";
    catppuccin.url = "github:catppuccin/nix";

    # Terminal

    zjstatus = {
      url = "github:dj95/zjstatus";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim
    nixCats.url = "github:BirdeeHub/nixCats-nvim";

    oxy2dev-nvim-scripts = {
      url = "github:OXY2DEV/nvim";
      flake = false;
    };

    plugins-cmp-dbee = {
      url = "github:MattiasMTS/cmp-dbee";
      flake = false;
    };

    plugins-gx-nvim = {
      url = "github:chrishrb/gx.nvim";
      flake = false;
    };

    plugins-maximize-nvim = {
      url = "github:declancm/maximize.nvim";
      flake = false;
    };

    plugins-nvim-dap-view = {
      url = "github:igorlfs/nvim-dap-view";
      flake = false;
    };

    plugins-webify-nvim = {
      url = "github:pabloariasal/webify.nvim";
      flake = false;
    };

    plugins-templ-goto-definition = {
      url = "github:catgoose/templ-goto-definition";
      flake = false;
    };

    plugins-tiny-code-actions = {
      url = "github:rachartier/tiny-code-action.nvim";
      flake = false;
    };

    plugins-cmp-go-deep = {
      url = "github:samiulsami/cmp-go-deep";
      flake = false;
    };

    plugins-inline-edit = {
      url = "github:AndrewRadev/inline_edit.vim";
      flake = false;
    };

    plugins-neotest-golang = {
      url = "github:fredrikaverpil/neotest-golang";
      flake = false;
    };

    plugins-neotest = {
      url = "github:nvim-neotest/neotest";
      flake = false;
    };

    plugins-warp-nvim = {
      url = "github:y3owk1n/warp.nvim";
      flake = false;
    };

    import-tree.url = "github:vic/import-tree";

    nixflix = {
      url = "github:kiriwalawren/nixflix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    opencode-antigravity-auth = {
      url = "github:NoeFabris/opencode-antigravity-auth/v1.6.0";
      flake = false;
    };

    nix-playwright-mcp = {
      url = "github:benjaminkitt/nix-playwright-mcp";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zellij-mcp = {
      url = "github:GitJuhb/zellij-mcp-server";
      flake = false;
    };

    omerxx-dotfiles = {
      url = "github:omerxx/dotfiles";
      flake = false;
    };

    get-shit-done = {
      url = "github:gsd-build/get-shit-done/v1.21.1";
      flake = false;
    };
  };

  outputs = inputs:
    (inputs.nixpkgs.lib.evalModules {
      modules = [
        (inputs.import-tree ./modules)
        (inputs.import-tree.match ".*/default\\.nix" ./hosts)
      ];
      specialArgs = {
        inherit inputs;
        inherit (inputs) self;
      };
    }).config.flake;
}

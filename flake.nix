# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    banterbus = {
      url = "gitlab:hmajid2301/banterbus";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    comma = {
      url = "github:nix-community/comma";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    den.url = "github:vic/den";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    goroutinely = {
      url = "gitlab:hmajid2301/goroutinely/fix-broken";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gothreads = {
      url = "gitlab:hmajid2301/gothreads";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gsesh = {
      url = "gitlab:hmajid2301/gsesh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    import-tree.url = "github:vic/import-tree";
    lanzaboote.url = "github:nix-community/lanzaboote";
    lettucego = {
      url = "gitlab:hmajid2301/lettucego";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nfsm = {
      url = "github:gvolpe/nfsm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
    nixery = {
      url = "github:tazjin/nixery";
      flake = false;
    };
    nixflix = {
      url = "github:kiriwalawren/nixflix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl.url = "github:nix-community/nixGL";
    nixos-anywhere = {
      url = "github:numtide/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    noctalia = {
      url = "github:noctalia-dev/noctalia/legacy-v4";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        noctalia-qs.follows = "noctalia-qs";
      };
    };
    noctalia-plugins = {
      url = "github:Mic92/noctalia-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    oxy2dev-nvim-scripts = {
      url = "github:OXY2DEV/nvim";
      flake = false;
    };
    pam-shim = {
      url = "github:Cu3PO42/pam_shim/next";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plugins-cmp-dbee = {
      url = "github:MattiasMTS/cmp-dbee";
      flake = false;
    };
    plugins-cmp-go-deep = {
      url = "github:samiulsami/cmp-go-deep";
      flake = false;
    };
    plugins-gx-nvim = {
      url = "github:chrishrb/gx.nvim";
      flake = false;
    };
    plugins-inline-edit = {
      url = "github:AndrewRadev/inline_edit.vim";
      flake = false;
    };
    plugins-maximize-nvim = {
      url = "github:declancm/maximize.nvim";
      flake = false;
    };
    plugins-neotest = {
      url = "github:nvim-neotest/neotest";
      flake = false;
    };
    plugins-neotest-golang = {
      url = "github:fredrikaverpil/neotest-golang";
      flake = false;
    };
    plugins-nvim-dap-view = {
      url = "github:igorlfs/nvim-dap-view";
      flake = false;
    };
    plugins-pi-nvim = {
      url = "github:carderne/pi-nvim";
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
    plugins-warp-nvim = {
      url = "github:y3owk1n/warp.nvim";
      flake = false;
    };
    plugins-webify-nvim = {
      url = "github:pabloariasal/webify.nvim";
      flake = false;
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix";
    tangled = {
      url = "git+https://tangled.sh/@tangled.sh/core";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zjstatus.url = "github:dj95/zjstatus";
  };
}

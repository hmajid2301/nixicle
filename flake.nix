# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    agent-skills.url = "github:Kyure-A/agent-skills-nix";
    banterbus = {
      url = "gitlab:hmajid2301/banterbus";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    caveman = {
      url = "github:JuliusBrussee/caveman";
      flake = false;
    };
    comma = {
      url = "github:nix-community/comma";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    den.url = "github:denful/den";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gitlab-ci-skill = {
      url = "git+https://gitlab.com/gitlab-org/ci-cd/gitlab-ci-skill.git";
      flake = false;
    };
    glci = {
      url = "git+https://gitlab.com/gitlab-org/ci-cd/runner-tools/glci.git";
      flake = false;
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
    herdr-skills = {
      url = "github:herdrdev/herdr/v0.8.2";
      flake = false;
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
    matt-skills = {
      url = "github:mattpocock/skills";
      flake = false;
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
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-community-plugins = {
      url = "github:noctalia-dev/community-plugins";
      flake = false;
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-official-plugins = {
      url = "github:noctalia-dev/official-plugins";
      flake = false;
    };
    nur.url = "github:nix-community/NUR";
    oxy2dev-nvim-scripts = {
      url = "github:OXY2DEV/nvim";
      flake = false;
    };
    playwright-cli-skill = {
      url = "github:microsoft/playwright-cli";
      flake = false;
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
    plugins-herdr-float = {
      url = "github:meerzulee/herdr-float";
      flake = false;
    };
    plugins-herdr-splits = {
      url = "github:lmilojevicc/herdr-splits.nvim";
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
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
    sure-nix = {
      url = "github:nSimonFR/sure-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tangled = {
      url = "git+https://tangled.sh/@tangled.sh/core";
      inputs = {
        fenix.follows = "fenix";
        nixpkgs.follows = "nixpkgs";
      };
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    worktrunk = {
      url = "github:max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zjstatus.url = "github:dj95/zjstatus";
  };
}

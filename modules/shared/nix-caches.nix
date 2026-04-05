{
  substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
    "https://numtide.cachix.org"
    "https://niri.cachix.org"
  ];

  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
  ];

  experimental-features = [
    "nix-command"
    "flakes"
  ];

  warn-dirty = false;
  use-xdg-base-directories = true;
}

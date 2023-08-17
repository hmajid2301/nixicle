{ pkgs, fetchFromGitHub }:

pkgs.vimUtils.buildVimPlugin {
  name = "hmts-nvim";

  src = fetchFromGitHub {
    owner = "calops";
    repo = "hmts.nvim";
    rev = "v1.2.0";
    hash = "sha256-il5m+GlNt0FzZjefl1q8ZxWHg0+gQps0vigt+eoIy8A=";
  };
}

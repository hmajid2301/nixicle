{
  pkgs,
  fetchFromGitHub,
}:
pkgs.vimUtils.buildVimPlugin {
  name = "codeium-nvim";

  src = fetchFromGitHub {
    owner = "Exafunction";
    repo = "codeium.vim";
    rev = "1.2.76";
    hash = "sha256-xXjLZ/bX9ANbQ9msSTEhGSkVav54PJ85aREwWSbB4Cw=";
  };
}

{
  pkgs,
  fetchFromGitHub,
}:
pkgs.vimUtils.buildVimPlugin {
  name = "maximize-nvim";

  src = fetchFromGitHub {
    owner = "declancm";
    repo = "maximize.nvim";
    rev = "97bfc171775c404396f8248776347ebe64474fe7";
    hash = "sha256-k8Cqti4nLUvtl0EBaU8ZPYJ6JlfnRlN6nCxE/WHrbnw=";
  };
}

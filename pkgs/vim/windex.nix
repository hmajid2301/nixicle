{
  pkgs,
  fetchFromGitHub,
}:
pkgs.vimUtils.buildVimPlugin {
  name = "windex-nvim";

  src = fetchFromGitHub {
    owner = "declancm";
    repo = "windex.nvim";
    rev = "1e86cba6f6f55ced60d17d6c6ebd51388a637b86";
    hash = "sha256-mkBfIrltEXw6o8eygg60cwcJyVfS5y8Hx7vtagvF3Vo=";
  };
}

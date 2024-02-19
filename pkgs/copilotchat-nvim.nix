{
  vimUtils,
  fetchFromGitHub,
  python3,
  buildEnv,
  lib,
}: let
  pname = "copilotchat-nvim";
  version = "1.3.0";
  src = fetchFromGitHub {
    owner = "CopilotC-Nvim";
    repo = "CopilotChat.nvim";
    rev = "v${version}";
    sha256 = "sha256-vbqtaRejGt+xXi1dfzclKL5/ZynEzBJfqXUHO+sC880=";
  };
  meta = {
    description = "Chat with GitHub Copilot in Neovim ";
    homepage = "https://github.com/CopilotC-Nvim/CopilotChat.nvim/";
    license = lib.licenses.gpl3;
  };
  lua = vimUtils.buildVimPlugin {
    pname = "${pname}-lua";
    inherit src version meta;
  };
  python = python3.withPackages (ps:
    with ps; [
      python-dotenv
      requests
      prompt-toolkit
      tiktoken
    ]);
in
  buildEnv {
    name = pname;

    paths = [
      lua
      python
    ];
  }

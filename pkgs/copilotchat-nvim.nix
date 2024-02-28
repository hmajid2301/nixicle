{
  vimUtils,
  fetchFromGitHub,
  python3,
  buildEnv,
  lib,
  ...
}: let
  pname = "copilotchat-nvim";
  version = "1.9.0";
  src = fetchFromGitHub {
    owner = "CopilotC-Nvim";
    repo = "CopilotChat.nvim";
    rev = "v${version}";
    sha256 = "sha256-Q0j1maM7cvRoHu18KGMw7vYkZBQv8H7jcurxgLHl3Lg=";
  };
  meta = {
    description = "Chat with GitHub Copilot in Neovim";
    homepage = "https://github.com/CopilotC-Nvim/CopilotChat.nvim/";
    license = lib.licenses.gpl3;
  };
  # Define the Python environment with the required packages
  pythonEnv = python3.withPackages (ps:
    with ps; [
      python-dotenv
      requests
      prompt-toolkit
      tiktoken
    ]);
  # Build the Vim plugin
  vimPlugin = vimUtils.buildVimPlugin {
    pname = "${pname}-lua";
    inherit src version meta;
    propagatedBuildInputs = [pythonEnv];
  };
in
  buildEnv {
    name = pname;
    paths = [vimPlugin pythonEnv];
    buildInputs = [pythonEnv];
  }

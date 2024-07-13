{
  lib,
  fetchFromGitLab,
  buildGoModule,
  installShellFiles,
}:
buildGoModule rec {
  pname = "optinix";
  version = "0.1.1";

  src = fetchFromGitLab {
    owner = "hmajid2301";
    repo = "optinix";
    rev = "v${version}";
    sha256 = "sha256-bRHesc03jExIL29BCP93cMbx+BOT4sHCu58JjpmRaeA=";
  };

  vendorHash = "sha256-uSFEhRWvJ83RGpekPJL9MOYJy2NfgVdZxuaNUMq3VaE=";

  nativeBuildInputs = [
    installShellFiles
  ];

  postInstall = ''
    installShellCompletion --cmd optinix \
      --bash <($out/bin/optinix completion bash) \
      --fish <($out/bin/optinix completion fish) \
      --zsh <($out/bin/optinix completion zsh)
  '';

  meta = with lib; {
    description = "A CLI tool for searching options in Nix, written in Go, powered by the bubbletea framework for TUI.";
    homepage = "https://gitlab.com/hmajid2301/optinix";
    license = licenses.mit;
    mainProgram = "optinix";
  };
}

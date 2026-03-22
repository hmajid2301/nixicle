{
  lib,
  buildGoApplication,
  makeWrapper,
  installShellFiles,
  zoxide,
}:
buildGoApplication {
  pname = "gsesh";
  version = "0.1.0";

  src = ./.;
  modules = ./gomod2nix.toml;

  nativeBuildInputs = [
    makeWrapper
  ];

  postInstall = ''
    wrapProgram $out/bin/gsesh \
      --prefix PATH : ${lib.makeBinPath [ zoxide ]}
  '';

  meta = with lib; {
    description = "Git session manager for worktrees + zellij";
    homepage = "https://github.com/hmajid2301/nixicle";
    license = licenses.mit;
    maintainers = [ ];
  };
}

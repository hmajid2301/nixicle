{
  lib,
  buildGoModule,
  makeWrapper,
  installShellFiles,
  zoxide,
}:
buildGoModule {
  pname = "gsesh";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-V/OhW39ON8jmj58awAHk1pOXFfykz+8L5n3O77wyqrw=";

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

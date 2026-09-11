{
  lib,
  buildGoModule,
  makeWrapper,
  openssh,
  rsync,
}:
buildGoModule {
  pname = "agent-session-sync";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  # No third-party dependencies — stdlib only.
  vendorHash = null;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/agent-session-sync \
      --prefix PATH : ${
        lib.makeBinPath [
          openssh
          rsync
        ]
      }
  '';

  meta = {
    description = "Mirror AI coding-agent transcripts from a remote machine so losing the box does not lose the conversations";
    mainProgram = "agent-session-sync";
    platforms = lib.platforms.unix;
  };
}

{
  lib,
  stdenv,
  pkgsCross,
  lld,
  makeWrapper,
  inputs,
  zsh,
  jq,
}:

let
  wasiPlatform = pkgsCross.wasi32.rustPlatform;

  plugin = wasiPlatform.buildRustPackage {
    pname = "zellij-pane-tracker";
    version = "0.1.0";

    src = inputs.zellij-pane-tracker;

    cargoLock.lockFile = ./Cargo.lock;

    postPatch = ''
      cp ${./Cargo.lock} Cargo.lock
    '';

    nativeBuildInputs = [ lld ];

    CARGO_TARGET_WASM32_WASIP1_LINKER = "wasm-ld";

    doCheck = false;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      cp target/wasm32-wasip1/release/zellij-pane-tracker.wasm $out/lib/zellij-pane-tracker.wasm
      runHook postInstall
    '';

    meta = with lib; {
      description = "Zellij plugin that exports pane names to JSON";
      homepage = "https://github.com/theslyprofessor/zellij-pane-tracker";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };
in
stdenv.mkDerivation {
  pname = "zellij-pane-tracker-plugin";
  version = "0.1.0";

  src = inputs.zellij-pane-tracker;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib

    cp "${plugin}/lib/zellij-pane-tracker.wasm" $out/lib/zellij-pane-tracker.wasm

    cp scripts/zjdump $out/bin/zjdump
    chmod +x $out/bin/zjdump
    wrapProgram $out/bin/zjdump \
      --prefix PATH : ${lib.makeBinPath [ zsh jq ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Zellij plugin + zjdump script that exports pane names to JSON";
    homepage = "https://github.com/theslyprofessor/zellij-pane-tracker";
    license = licenses.mit;
    platforms = platforms.all;
  };
}

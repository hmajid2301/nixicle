{ lib, inputs, system, pkgs, cargoLockFile, src ? null }:

let
  pname = "zellij-detach";
  version = "unstable";
  target = "wasm32-wasip1";

  # Use local source with modifications if src is provided, otherwise use upstream
  pluginSrc = if src != null then src else inputs.zellij-detach;

  cargoLockInStore = builtins.path {
    path = cargoLockFile;
    name = "zellij-detach-cargo-lock";
  };

  fenixPkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [ inputs.fenix.overlays.default ];
  };

  toolchain = fenixPkgs.fenix.combine [
    fenixPkgs.fenix.stable.rustc
    fenixPkgs.fenix.stable.cargo
    fenixPkgs.fenix.targets.${target}.stable.rust-std
  ];

  rustPlatform = fenixPkgs.makeRustPlatform {
    cargo = toolchain;
    rustc = toolchain;
  };
in
rustPlatform.buildRustPackage {
  inherit pname version;
  src = pluginSrc;

  cargoLock.lockFile = cargoLockInStore;

  postUnpack = ''
    cp ${cargoLockInStore} $sourceRoot/Cargo.lock
  '';

  buildPhase = ''
    cargo build --release --target ${target}
  '';

  installPhase = ''
    mkdir -p $out
    cp target/${target}/release/${pname}.wasm $out/${pname}.wasm
  '';

  doCheck = false;

  meta = with lib; {
    description = "Zellij plugin for CLI-based detach with command support";
    homepage = "https://github.com/karlbunch/zellij-detach";
    license = licenses.mit;
  };
}

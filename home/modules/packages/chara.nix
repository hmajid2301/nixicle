{ lib, fetchFromGitHub, rustPlatform, installShellFiles, ... }:

rustPlatform.buildRustPackage rec {
  pname = "charasay";
  version = "v2.0.0";

  src = fetchFromGitHub {
    owner = "latipun7";
    repo = pname;
    rev = version;
    hash = "sha256-99lMXgSHgxKc0GHnRRciMoZ+rQJyMAx+27fj6NkXxds=";
  };

  cargoHash = "sha256-bLzk/IgQniu04VZCaaCETEQxLtesMtJuBBWezYecN0A=";

  meta = with lib; {
    description = "The future of cowsay! Colorful characters saying something.";
    homepage = "https://github.com/latipun7/charasay";
    license = licenses.mit;
    maintainers = [ "latipun7" ];
  };

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd himalaya \
      --bash <($out/bin/chara completion --shell bash) \
      --fish <($out/bin/chara completion --shell fish) \
      --zsh <($out/bin/chara completion --shell zsh)
  '';
}


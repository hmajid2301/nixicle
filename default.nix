{
  lib,
  python3,
  fetchFromGitHub,
}:
python3.pkgs.buildPythonApplication rec {
  pname = "mk";
  version = "2.7.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pycontribs";
    repo = "mk";
    rev = "v${version}";
    hash = "sha256-hhuvUmDqE2fUD1iYn44p5YQcjYx9DV3MYSsqHA0wMhQ=";
  };

  build-system = [
    python3.pkgs.setuptools
    python3.pkgs.setuptools-scm
  ];

  pythonImportsCheck = [
    "mk"
  ];

  postInstall = ''
    installShellCompletion --cmd mk \
      --bash <($out/bin/mk completion bash) \
      --fish <($out/bin/mk completion fish) \
      --zsh <($out/bin/mk completion zsh)
  '';

  meta = {
    description = "Mk ease contributing to any open source repository by exposing most common actions you can run. Inspired by make, tox and other cool tools";
    homepage = "https://github.com/pycontribs/mk";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
    mainProgram = "mk";
  };
}

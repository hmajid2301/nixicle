{
  lib,
  pkgs,
  fetchFromGitHub,
  buildHomeAssistantComponent,
}:
buildHomeAssistantComponent rec {
  owner = "BottlecapDave";
  domain = "octopus_energy";
  version = "14.0.0-beta.1";
  format = "other";

  src = fetchFromGitHub {
    owner = "BottlecapDave";
    repo = "HomeAssistant-OctopusEnergy";
    rev = "v${version}";
    sha256 = "sha256-5UX74mgg9eV6kdupB42RrxTnNeLyeOScVg41mMhfARo=";
  };

  checkInputs = with pkgs.python312Packages;
  with pkgs; [
    home-assistant
    mock
    psutil-home-assistant
    pytest
    pytest-socket
    pytest-asyncio
    sqlalchemy
    pydantic
  ];

  # checkPhase = ''
  #   python -m pytest tests/unit
  # '';

  meta = with lib; {
    homepage = "https://github.com/BottlecapDave/HomeAssistant-OctopusEnergy";
    license = licenses.mit;
    description = "Custom component to bring your Octopus Energy details into Home Assistant";
  };
}

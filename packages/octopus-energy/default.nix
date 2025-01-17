{
  lib,
  pkgs,
  fetchFromGitHub,
  buildHomeAssistantComponent,
}:
buildHomeAssistantComponent rec {
  owner = "BottlecapDave";
  domain = "octopus_energy";
  version = "13.5.3";
  format = "other";

  src = fetchFromGitHub {
    owner = "BottlecapDave";
    repo = "HomeAssistant-OctopusEnergy";
    rev = "v${version}";
    sha256 = "sha256-qkPHb4o6rwXvifT+1L/pmpmJy3Qv4+ZYlhMn/cDnYDA=";
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

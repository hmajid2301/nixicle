{
  lib,
  pkgs,
  fetchFromGitHub,
  buildHomeAssistantComponent,
}:
buildHomeAssistantComponent rec {
  owner = "graham33";
  domain = "octopus-energy";
  version = "12.2.0";
  format = "other";

  src = fetchFromGitHub {
    owner = "BottlecapDave";
    repo = "HomeAssistant-OctopusEnergy";
    rev = "v${version}";
    sha256 = "sha256-qBvr+7oMAhTyxlWSo+CPddZ00aIGt+0s3x/LlEKUrN4=";
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
  ];

  checkPhase = ''
    python -m pytest tests/unit
  '';

  meta = with lib; {
    homepage = "https://github.com/BottlecapDave/HomeAssistant-OctopusEnergy";
    license = licenses.mit;
    description = "Custom component to bring your Octopus Energy details into Home Assistant";
    maintainers = with maintainers; [graham33];
  };
}

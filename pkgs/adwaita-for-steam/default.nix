{
  stdenvNoCC,
  fetchFromGitHub,
  python3,
  config,
  ...
}:
stdenvNoCC.mkDerivation rec {
  name = "adwaita-for-steam";
  version = "1.15";

  src = fetchFromGitHub {
    owner = "tkashkin";
    repo = "Adwaita-for-Steam";
    rev = "v${version}";
    sha256 = "eWnq+Sag9WfhzWqv0Vin0zs0pjHrFFgE4mKKg5PwVlc=";
  };

  preferLocalBuild = true;

  nativeBuildInputs = [python3];

  patches = [./install.patch];

  installPhase = ''
    mkdir -p $out/build
    NIX_OUT="$out" python install.py -c catppuccin-mocha  -e login/hide_qr -e library/hide_whats_new -e general/no_rounded_corners
  '';
}

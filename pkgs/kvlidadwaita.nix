{
  lib,
  pkgs,
  ...
}:
with pkgs; let
  repo = "https://github.com/GabePoel/KvLibadwaita";
  rev = "61f2e0b04937b6d31f0f4641c9c9f1cc3600a723";
  sha256 = "sha256-65Gz3WNAwuoWWbBZJL0Ifl+PVLOHjpl6GNhR1oVmGZ0=";
in
  stdenv.mkDerivation rec {
    pname = "KvLibadwaita";
    version = rev;

    src = fetchFromGitHub {
      owner = "GabePoel";
      repo = pname;
      inherit rev sha256;
    };

    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/Kvantum/
      cp -r ./src/. $out/share/Kvantum/
    '';

    meta = with lib; {
      description = "Libadwaita style theme for Kvantum";
      homepage = repo;
      license = licenses.gpl3Only;
      maintainers = ["maydayv7"];
    };
  }

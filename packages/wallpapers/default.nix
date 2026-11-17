{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  wallpaperDir = "${inputs.nixicle-assets}/wallpapers";
  images = builtins.attrNames (builtins.readDir wallpaperDir);

  # Helper to get filename without extension (replaces lib.snowfall.path.get-file-name-without-extension)
  getNameWithoutExt =
    filename:
    let
      parts = lib.splitString "." filename;
    in
    if builtins.length parts > 1 then lib.concatStringsSep "." (lib.init parts) else filename;

  mkWallpaper =
    name: src:
    let
      fileName = builtins.baseNameOf src;
      pkg = pkgs.stdenvNoCC.mkDerivation {
        inherit name src;

        dontUnpack = true;

        installPhase = ''
          cp $src $out
        '';

        passthru = { inherit fileName; };
      };
    in
    pkg;
  names = builtins.map getNameWithoutExt images;
  wallpapers = lib.foldl (
    acc: image:
    let
      name = getNameWithoutExt image;
    in
    acc // { "${name}" = mkWallpaper name (wallpaperDir + "/${image}"); }
  ) { } images;
  installTarget = "$out/share/wallpapers";
in
pkgs.stdenvNoCC.mkDerivation {
  name = "wallpapers";
  src = wallpaperDir;

  installPhase = ''
    mkdir -p ${installTarget}

    find * -type f -mindepth 0 -maxdepth 0 -exec cp ./{} ${installTarget}/{} ';'
  '';

  passthru = {
    inherit names;
  }
  // wallpapers;
}

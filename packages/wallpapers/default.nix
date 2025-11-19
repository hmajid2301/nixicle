{
  pkgs,
  lib,
  ...
}: let
  # Helper to get filename without extension (replacement for lib.snowfall.path.get-file-name-without-extension)
  getFileNameWithoutExtension = path: let
    baseName = builtins.baseNameOf (toString path);
    parts = lib.splitString "." baseName;
  in
    if builtins.length parts > 1
    then lib.concatStringsSep "." (lib.init parts)
    else baseName;

  images = builtins.attrNames (builtins.readDir ./wallpapers);
  mkWallpaper = name: src: let
    fileName = builtins.baseNameOf src;
    pkg = pkgs.stdenvNoCC.mkDerivation {
      inherit name src;

      dontUnpack = true;

      installPhase = ''
        cp $src $out
      '';

      passthru = {inherit fileName;};
    };
  in
    pkg;
  names = builtins.map getFileNameWithoutExtension images;
  wallpapers =
    lib.foldl
    (acc: image: let
      name = getFileNameWithoutExtension image;
    in
      acc // {"${name}" = mkWallpaper name (./wallpapers + "/${image}");})
    {}
    images;
  installTarget = "$out/share/wallpapers";
  installWallpapers =
    builtins.mapAttrs
    (name: wallpaper: ''
      cp ${wallpaper} ${installTarget}/${wallpaper.fileName}
    '')
    wallpapers;
in
  pkgs.stdenvNoCC.mkDerivation {
    name = "wallpapers";
    src = ./wallpapers;

    installPhase = ''
      mkdir -p ${installTarget}

      find * -type f -mindepth 0 -maxdepth 0 -exec cp ./{} ${installTarget}/{} ';'
    '';

    passthru = {inherit names;} // wallpapers;
  }

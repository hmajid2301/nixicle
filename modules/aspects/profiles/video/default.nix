{ den, ... }:
let
  # davinci-resolve-studio 21.1's source hash changed upstream. The fix
  # (nixpkgs master cb77d0acc2) is not on nixos-unstable yet, so patch the
  # fixed-output hash here. Remove once `nix flake update` picks it up.
  davinciSrcHashFix = _final: prev: {
    davinci-resolve-studio =
      prev.callPackage "${prev.path}/pkgs/by-name/da/davinci-resolve/package.nix"
        {
          studioVariant = true;
          runCommandLocal =
            name: args: body:
            prev.runCommandLocal name (
              if (args.outputHash or null) == "sha256-D5RjUukwKMpULrDfMJOPsPWW9FxhQ/IUMh76u5JLytA=" then
                args // { outputHash = "sha256-P+zu8/OuFcDcIkwV3UMq0qg9U2JEGRkKDP+VLQesZjw="; }
              else
                args
            ) body;
        };
  };
in
{
  den.aspects.video = {
    includes = [
      den.aspects.obs
      (den.batteries.unfree [ "davinci-resolve-studio" ])
    ];

    homeManager =
      { pkgs, ... }:
      {
        nixpkgs.overlays = [ davinciSrcHashFix ];

        home.packages = with pkgs; [
          audacity
          davinci-resolve-studio
        ];
      };
  };
}

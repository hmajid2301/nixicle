{ den, lib, ... }:
{
  den.aspects.overlays = {
    includes = [ ];
    nixos =
      { lib, ... }:
      {
        nixpkgs.overlays = [
          # TODO: remove once https://github.com/NixOS/nixpkgs/pull/514576 is merged
          (final: prev: {
            efitools = prev.efitools.overrideAttrs (old: {
              postPatch =
                (old.postPatch or "")
                + ''
                  substituteInPlace Make.rules \
                    --replace-fail '--target=efi-app-$(ARCH)' '--output-target=efi-app-$(ARCH)'
                '';
            });
          })
        ];
      };
  };
}

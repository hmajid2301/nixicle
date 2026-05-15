{ ... }:
{
  den.aspects.overlays = {
    includes = [ ];
    nixos =
      { ... }:
      {
        nixpkgs.overlays = [
          # TODO: remove once https://github.com/NixOS/nixpkgs/pull/514576 is merged
          (_final: prev: {
            efitools = prev.efitools.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                substituteInPlace Make.rules \
                  --replace-quiet '--target=efi-app-$(ARCH)' '--output-target=efi-app-$(ARCH)'
              '';
            });
          })
        ];
      };
  };
}

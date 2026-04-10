{ den, lib, ... }:
# Returns an include that forwards the aspect's `persist.directories` into
# nixos at environment.persistence."/persist".directories, but only when the
# impermanence module is loaded.
# Uses lib.optionalAttrs (truly lazy) so that the environment.persistence option
# path is never evaluated on hosts without impermanence.
{ aspect-chain, ... }:
let
  asp = lib.head aspect-chain;
  dirs = asp.persist.directories or [ ];
in
{
  nixos =
    { options, ... }:
    lib.optionalAttrs (dirs != [ ] && options ? environment && options.environment ? persistence) {
      environment.persistence."/persist".directories = dirs;
    };
}

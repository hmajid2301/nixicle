{lib, ...}: let
  inherit (lib) types mkOption;
in {
  options.host = mkOption {
    type = types.str;
    default = "";
    description = ''
      Name of the host
    '';
  };
}

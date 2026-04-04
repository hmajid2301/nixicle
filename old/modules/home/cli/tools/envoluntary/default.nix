{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.cli.tools.envoluntary;
  
  tomlFormat = pkgs.formats.toml { };
in
{
  options.cli.tools.envoluntary = {
    config = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Configuration for envoluntary.
        Install envoluntary with: cargo install envoluntary
      '';
      example = lib.literalExpression ''
        {
          entries = [
            {
              pattern = ".*/projects/my-website(/.*)?";
              flake_reference = "~/nix-dev-shells/nodejs";
              impure = true;
            }
            {
              pattern = "~/projects/rust-.*";
              flake_reference = "github:NixOS/templates/30a6f18?dir=rust";
            }
            {
              pattern = ".*";
              pattern_adjacent = ".*/Cargo\\.toml";
              flake_reference = "github:NixOS/templates/30a6f18?dir=rust";
            }
          ];
        }
      '';
    };
  };

  config = lib.mkIf (cfg.config != { }) {
    xdg.configFile."envoluntary/config.toml" = {
      source = tomlFormat.generate "envoluntary-config.toml" cfg.config;
    };
  };
}

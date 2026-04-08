# Adds custom spec fields (postpkgs, mainInfo, settings) and helper functions.
# Closely follows the birdeevim nvim-lib.nix pattern.
{
  config,
  lib,
  wlib,
  pkgs,
  inputs,
  ...
}:
{
  # Expose the enabled/disabled state of each spec to Lua via nixInfo("settings","cats","<name>")
  options.settings.cats = lib.mkOption {
    readOnly = true;
    type = lib.types.attrsOf lib.types.raw;
    default = builtins.mapAttrs (_: v: v.enable) config.specs;
    description = "Map of spec name -> enabled boolean, exposed via nixInfo";
  };

  # Build vim plugins from flake inputs with a plugins-* prefix
  options.nvim-lib.pluginsFromPrefix = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default =
      prefix: inps:
      lib.pipe inps [
        builtins.attrNames
        (builtins.filter (s: lib.hasPrefix prefix s))
        (map (
          input:
          let
            name = lib.removePrefix prefix input;
          in
          {
            inherit name;
            value = config.nvim-lib.mkPlugin name inps.${input};
          }
        ))
        builtins.listToAttrs
      ];
  };

  # All plugins built from plugins-* inputs
  options.nvim-lib.neovimPlugins = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = config.nvim-lib.pluginsFromPrefix "plugins-" inputs;
  };

  # Add postpkgs, prepkgs, mainInfo, and settings fields to every spec
  config.specMods =
    { config, ... }:
    let
      wrappers = lib.pipe config.wrappers [
        builtins.attrValues
        (builtins.filter (v: v.enable))
        (lib.partition (v: v.prefix))
        (
          { right, wrong }:
          {
            pre = map (v: v.wrapper) right;
            post = map (v: v.wrapper) wrong;
          }
        )
      ];
    in
    {
      options.prepkgs = lib.mkOption {
        type = lib.types.listOf wlib.types.stringable;
        description = "Packages prepended to PATH for this spec";
      };
      config.prepkgs = wrappers.pre;
      options.postpkgs = lib.mkOption {
        type = lib.types.listOf wlib.types.stringable;
        description = "Packages appended to PATH for this spec";
      };
      config.postpkgs = wrappers.post;
      options.mainInfo = lib.mkOption {
        type = wlib.types.attrsRecursive;
        default = { };
        description = "Extra info merged into the top-level info plugin (accessible via nixInfo)";
      };
      options.settings = lib.mkOption {
        type = lib.types.submoduleWith { modules = [ { freeformType = wlib.types.attrsRecursive; } ]; };
        default = { };
        description = "Freeform per-spec settings";
      };
      options.wrappers = lib.mkOption {
        type = lib.types.attrsOf (
          wlib.types.subWrapperModule {
            config.pkgs = pkgs;
            options.prefix = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            options.enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
          }
        );
        default = { };
        description = "Per-spec wrapper modules";
      };
    };

  # Collect all mainInfo values and merge into config.info
  config.info = lib.mkMerge (
    config.specCollect (acc: v: acc ++ lib.optional (v.mainInfo or { } != { }) v.mainInfo) [ ]
  );

  # Collect prepkgs into a PATH prefix variable
  config.prefixVar =
    let
      autodeps = config.specCollect (acc: v: acc ++ (v.prepkgs or [ ])) [ ];
    in
    lib.optional (autodeps != [ ]) {
      name = "PREPKGS_ADDITIONS";
      data = [
        "PATH"
        ":"
        "${lib.makeBinPath (lib.unique autodeps)}"
      ];
    };

  # Collect postpkgs into a PATH suffix variable
  config.suffixVar =
    let
      autodeps = config.specCollect (acc: v: acc ++ (v.postpkgs or [ ])) [ ];
    in
    lib.optional (autodeps != [ ]) {
      name = "POSTPKGS_ADDITIONS";
      data = [
        "PATH"
        ":"
        "${lib.makeBinPath (lib.unique autodeps)}"
      ];
    };
}

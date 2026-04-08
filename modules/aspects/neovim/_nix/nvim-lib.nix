{
  config,
  lib,
  wlib,
  pkgs,
  inputs,
  ...
}:
{
  options.settings.cats = lib.mkOption {
    readOnly = true;
    type = lib.types.attrsOf lib.types.raw;
    default = builtins.mapAttrs (_: v: v.enable) config.specs;
  };

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

  options.nvim-lib.neovimPlugins = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default = config.nvim-lib.pluginsFromPrefix "plugins-" inputs;
  };

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
      };
      config.prepkgs = wrappers.pre;
      options.postpkgs = lib.mkOption {
        type = lib.types.listOf wlib.types.stringable;
      };
      config.postpkgs = wrappers.post;
      options.mainInfo = lib.mkOption {
        type = wlib.types.attrsRecursive;
        default = { };
      };
      options.settings = lib.mkOption {
        type = lib.types.submoduleWith { modules = [ { freeformType = wlib.types.attrsRecursive; } ]; };
        default = { };
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
      };
    };

  config.info = lib.mkMerge (
    config.specCollect (acc: v: acc ++ lib.optional (v.mainInfo or { } != { }) v.mainInfo) [ ]
  );

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

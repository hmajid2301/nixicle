{ lib, inputs }:
# Credit: @JakeHamilton and @thursdaddy
# Adapted from https://github.com/jakehamilton/config and https://github.com/thursdaddy/nixos-config

with lib;
rec {
  ## Create a NixOS module option.
  ##
  ## ```nix
  ## lib.nixicle.mkOpt nixpkgs.lib.types.str "My default" "Description of my option."
  ## ```
  ##
  #@ Type -> Any -> String
  mkOpt =
    type: default: description:
    mkOption { inherit type default description; };

  ## Create a NixOS module option without a description.
  ##
  ## ```nix
  ## lib.nixicle.mkOpt' nixpkgs.lib.types.str "My default"
  ## ```
  ##
  #@ Type -> Any -> String
  mkOpt' = type: default: mkOpt type default null;

  ## Create a NixOS module option with no default
  ##
  ## ```nix
  ## lib.nixicle.mkOpt_ types.path "Description of my option"
  ## ```
  ##
  #@ Type -> Any -> String
  mkOpt_ = type: description: mkOption { inherit type description; };

  ## Create a boolean option with a default value and description.
  ##
  ## ```nix
  ## lib.nixicle.mkBoolOpt true "Enable this feature"
  ## ```
  ##
  #@ Bool -> String
  mkBoolOpt = mkOpt types.bool;

  ## Create a boolean option with a default value but no description.
  ##
  ## ```nix
  ## lib.nixicle.mkBoolOpt' false
  ## ```
  ##
  #@ Bool
  mkBoolOpt' = mkOpt' types.bool;

  ## Create a package option with a default value and description.
  ##
  ## ```nix
  ## lib.nixicle.mkPackageOpt pkgs.vim "The editor to use"
  ## ```
  ##
  #@ Package -> String
  mkPackageOpt = mkOpt types.package;

  ## Create a package option with a default value but no description.
  ##
  ## ```nix
  ## lib.nixicle.mkPackageOpt' pkgs.vim
  ## ```
  ##
  #@ Package
  mkPackageOpt' = mkOpt' types.package;

  enabled = {
    ## Quickly enable an option.
    ##
    ## ```nix
    ## services.nginx = enabled;
    ## ```
    ##
    #@ true
    enable = true;
  };

  disabled = {
    ## Quickly disable an option.
    ##
    ## ```nix
    ## services.nginx = disabled;
    ## ```
    ##
    #@ false
    enable = false;
  };

  # Deploy-rs helper
  inherit (import ./deploy { inherit lib inputs; }) mkDeploy;

  # Traefik helpers
  inherit (import ./traefik { inherit lib; }) mkTraefikService mkAuthenticatedTraefikService;

  # Recursively import all modules from a directory
  # Returns a list of module paths that can be used in imports
  importModulesRecursive = dir:
    let
      entries = builtins.readDir dir;
      hasDefaultNix = builtins.pathExists (dir + "/default.nix");

      # Process each entry in the directory
      processEntry = name: type:
        let
          path = dir + "/${name}";
        in
        if type == "directory" then
          # Recurse into subdirectories
          importModulesRecursive path
        else if type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix" && !hasDefaultNix then
          # Only include standalone .nix files if there's NO default.nix in the current directory
          # This prevents importing helper files alongside a default.nix module
          [ path ]
        else
          [ ];

      # Map over all entries and flatten
      subdirModules = lib.flatten (lib.mapAttrsToList processEntry entries);

      # If this directory has a default.nix, include it
      result = if hasDefaultNix then [ dir ] ++ subdirModules else subdirModules;
    in
    result;

  # Import all modules and return as a single module that imports them all
  mkModuleTree = dir: {
    imports = importModulesRecursive dir;
  };

  # Recursively find and import all packages from a directory
  # Each package should be a directory with default.nix
  importPackages = pkgs: dir:
    let
      entries = builtins.readDir dir;

      processEntry = name: type:
        if type == "directory" && builtins.pathExists (dir + "/${name}/default.nix") then
          { ${name} = pkgs.callPackage (dir + "/${name}") { }; }
        else
          { };
    in
    lib.foldl' (acc: entry: acc // entry) { } (lib.mapAttrsToList processEntry entries);

  # Recursively find and apply all overlays from a directory
  importOverlays = dir:
    let
      entries = builtins.readDir dir;

      processEntry = name: type:
        if type == "directory" && builtins.pathExists (dir + "/${name}/default.nix") then
          [ (dir + "/${name}") ]
        else if type == "regular" && lib.hasSuffix ".nix" name then
          [ (dir + "/${name}") ]
        else
          [ ];
    in
    lib.flatten (lib.mapAttrsToList processEntry entries);

  # Get all .nix files in a directory except default.nix
  # Replaces lib.snowfall.fs.get-non-default-nix-files
  getNonDefaultNixFiles = dir:
    let
      entries = builtins.readDir dir;

      processEntry = name: type:
        if type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix" then
          [ (dir + "/${name}") ]
        else
          [ ];
    in
    lib.flatten (lib.mapAttrsToList processEntry entries);
}

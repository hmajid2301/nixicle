{ lib, inputs }:
let
  # Import sub-libraries
  module = import ./module { inherit lib; };
  deploy = import ./deploy { inherit lib inputs; };
  traefik = import ./traefik { inherit lib; };
in
rec {
  # Re-export module functions
  inherit (module) mkOpt mkOpt' mkBoolOpt mkBoolOpt' mkPackageOpt mkPackageOpt' enabled disabled;

  # Re-export deploy functions
  inherit (deploy) mkDeploy;

  # Re-export traefik functions
  inherit (traefik) mkTraefikService mkAuthenticatedTraefikService;

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

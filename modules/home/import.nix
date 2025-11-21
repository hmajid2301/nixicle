# Credit: @infinisil
# Adapted from https://github.com/thursdaddy/nixos-config/blob/main/modules/nixos/import.nix
# Automatically discovers and imports all default.nix files from subdirectories

let
  # Recursively finds all default.nix files in subdirectories
  getDefaultNix = dir:
    let
      # Read directory entries
      entries = builtins.readDir dir;

      # Process each entry
      processEntry = name: type:
        let
          path = dir + "/${name}";
        in
        if type == "directory" then
          # Recurse into directories
          getDefaultNix path
        else if type == "regular" && name == "default.nix" then
          # Include default.nix files, but not from the current directory
          # (which would be import.nix's directory)
          [ ]
        else
          [ ];

      # Check if the current directory has a default.nix
      hasDefaultNix = builtins.pathExists (dir + "/default.nix");

      # Get all modules from subdirectories
      subdirModules = builtins.concatLists (builtins.attrValues (builtins.mapAttrs processEntry entries));
    in
    # If this directory has a default.nix and it's not the root (import.nix location), include it
    if hasDefaultNix && dir != ./. then
      [ dir ] ++ subdirModules
    else
      subdirModules;
in
{
  # Auto-import all default.nix files from subdirectories
  imports = getDefaultNix ./.;
}

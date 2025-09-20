# locals {
#   ipv4 = "192.0.2.1"
# }

# module "system-build" {
#   source            = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
#   # with flakes
#   attribute         = ".#nixosConfigurations.mymachine.config.system.build.toplevel"
#   # without flakes
#   # file can use (pkgs.nixos []) function from nixpkgs
#   #file              = "${path.module}/../.."
#   #attribute         = "config.system.build.toplevel"
# }

# module "disko" {
#   source         = "github.com/nix-community/nixos-anywhere//terraform/nix-build"
#   # with flakes
#   attribute      = ".#nixosConfigurations.mymachine.config.system.build.diskoScript"
#   # without flakes
#   # file can use (pkgs.nixos []) function from nixpkgs
#   #file           = "${path.module}/../.."
#   #attribute      = "config.system.build.diskoScript"
# }

# module "install" {
#   source            = "github.com/nix-community/nixos-anywhere//terraform/install"
#   nixos_system      = module.system-build.result.out
#   nixos_partitioner = module.disko.result.out
#   target_host       = local.ipv4
# }

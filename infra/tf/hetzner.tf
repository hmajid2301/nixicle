# terraform {
#   required_providers {
#     hcloud = {
#       source  = "hetznercloud/hcloud"
#       version = "~> 1.49"
#     }
#   }
# }

# variable "hcloud_token" {
#   description = "Hetzner Cloud API token"
#   type        = string
#   sensitive   = true
# }

# provider "hcloud" {
#   token = var.hcloud_token
# }

# resource "hcloud_network" "private_network" {
#   name     = "private-network"
#   ip_range = "10.0.0.0/16"
# }

# resource "hcloud_network_subnet" "default_private_network_subnet" {
#   type         = "cloud"
#   network_id   = hcloud_network.private_network.id
#   network_zone = "eu-central"
#   ip_range     = "10.0.1.0/24"
# }

# Uncomment and modify if importing existing server
# resource "hcloud_server" "db_server" {
#   name        = "existing-db-server"
#   server_type = "cx22"
#   image       = "debian-12"
#   location    = "nbg1"
#
#   network {
#     network_id = hcloud_network.private_network.id
#     ip         = "10.0.1.3"
#   }
#
#   ssh_keys = ["default-ssh-key"]
# }

# For importing existing server, use data source
# data "hcloud_server" "existing_db_server" {
#   name = "your-existing-server-name"
# }

# module "nixos_install_db_server" {
#   source      = "./modules/nixos-install"
#   target_host = data.hcloud_server.existing_db_server.ipv4_address
# }
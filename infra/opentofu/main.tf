terraform {
  required_providers {
    pocketid = {
      source  = "trozz/pocketid"
      version = "~> 2.3"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
    gandi = {
      source  = "go-gandi/gandi"
      version = "~> 2.3"
    }
  }
  required_version = ">= 1.0"
}

provider "pocketid" {
  api_token = var.pocketid_api_token
  base_url  = var.pocketid_base_url
}

provider "vault" {
  address          = var.openbao_address
  skip_child_token = true
  token            = var.openbao_token
}

variable "openbao_address" {
  description = "OpenBao/Vault API URL."
  type        = string
  default     = "https://openbao.homelab.haseebmajid.dev"
}

variable "openbao_token" {
  description = "OpenBao/Vault token used by the Vault provider."
  type        = string
  sensitive   = true
}

variable "pocketid_api_token" {
  description = "Pocket-ID admin API token"
  type        = string
  sensitive   = true
}

variable "pocketid_base_url" {
  description = "Pocket-ID base URL, e.g. https://id.haseebmajid.dev"
  type        = string
}

data "pocketid_group" "family" {
  name = "family"
}

# OIDC clients, one entry per app. Values here are the old per-resource
# attributes, verbatim; `client_id` doubles as the map key for readability.
locals {
  oidc_apps = {
    dynacat = {
      client_id           = "dynacat"
      name                = "Dynacat"
      launch_url          = "https://dynacat.haseebmajid.dev"
      callback_urls       = ["https://dynacat.haseebmajid.dev/api/oidc/callback"]
      pkce_enabled        = true
      is_public           = false
      allowed_user_groups = [data.pocketid_group.family.id]
    }
    goroutinely = {
      client_id           = "goroutinely"
      name                = "Goroutinely"
      launch_url          = "https://goroutinely.haseebmajid.dev"
      callback_urls       = ["https://goroutinely.haseebmajid.dev/callback"]
      pkce_enabled        = true
      is_public           = false
      allowed_user_groups = [data.pocketid_group.family.id]
    }
    gotify = {
      client_id           = "gotify"
      name                = "Gotify"
      launch_url          = "https://gotify.haseebmajid.dev"
      callback_urls       = ["https://gotify.haseebmajid.dev/auth/oidc/callback", "gotify://oidc/callback"]
      pkce_enabled        = true
      is_public           = false
      allowed_user_groups = [data.pocketid_group.family.id, pocketid_group.gotify_admins.id]
    }
    gothreads = {
      client_id           = "gothreads"
      name                = "GoThreads"
      launch_url          = "https://gothreads.haseebmajid.dev"
      callback_urls       = ["https://gothreads.haseebmajid.dev/callback"]
      pkce_enabled        = true
      is_public           = false
      allowed_user_groups = [data.pocketid_group.family.id]
    }
    grafana = {
      client_id           = "grafana"
      name                = "Grafana"
      launch_url          = "https://grafana.homelab.haseebmajid.dev"
      callback_urls       = ["https://grafana.homelab.haseebmajid.dev/login/generic_oauth"]
      pkce_enabled        = false
      is_public           = false
      allowed_user_groups = [data.pocketid_group.family.id, pocketid_group.grafana_admins.id, pocketid_group.grafana_editors.id]
    }
    hister = {
      client_id           = "hister"
      name                = "Hister"
      launch_url          = "https://hister.haseebmajid.dev"
      callback_urls       = ["https://hister.haseebmajid.dev/api/oauth/callback?provider=oidc"]
      pkce_enabled        = false
      is_public           = false
      allowed_user_groups = []
    }
    immich = {
      client_id           = "immich"
      name                = "Immich"
      launch_url          = "https://immich.haseebmajid.dev"
      callback_urls       = ["https://immich.haseebmajid.dev/auth/login", "https://immich.haseebmajid.dev/user-settings", "app.immich:///oauth-callback"]
      pkce_enabled        = true
      is_public           = false
      allowed_user_groups = [data.pocketid_group.family.id]
    }
    jellyfin = {
      client_id           = "jellyfin"
      name                = "Jellyfin"
      launch_url          = "https://jellyfin.haseebmajid.dev"
      callback_urls       = ["https://jellyfin.haseebmajid.dev/sso/OID/r/pocketid", "https://jellyfin.haseebmajid.dev/sso/OID/redirect/pocketid"]
      pkce_enabled        = true
      is_public           = false
      allowed_user_groups = [data.pocketid_group.family.id]
    }
    karakeep = {
      client_id           = "karakeep"
      name                = "KaraKeep"
      launch_url          = "https://karakeep.haseebmajid.dev"
      callback_urls       = ["https://karakeep.haseebmajid.dev/api/auth/callback/custom"]
      pkce_enabled        = true
      is_public           = false
      allowed_user_groups = [data.pocketid_group.family.id]
    }
    lettucego = {
      client_id           = "lettucego"
      name                = "LettuceGo"
      launch_url          = "https://lettucego.haseebmajid.dev"
      callback_urls       = ["https://lettucego.haseebmajid.dev/callback"]
      pkce_enabled        = true
      is_public           = false
      allowed_user_groups = [data.pocketid_group.family.id]
    }
    papra = {
      client_id           = "papra"
      name                = "Papra"
      launch_url          = "https://papra.haseebmajid.dev"
      callback_urls       = ["https://papra.haseebmajid.dev/api/auth/oauth2/callback/pocketid"]
      pkce_enabled        = true
      is_public           = false
      allowed_user_groups = [data.pocketid_group.family.id]
    }
    sure = {
      client_id           = "sure"
      name                = "Sure"
      launch_url          = "https://sure.haseebmajid.dev"
      callback_urls       = ["https://sure.haseebmajid.dev/auth/pocketid/callback"]
      pkce_enabled        = true
      is_public           = false
      allowed_user_groups = [data.pocketid_group.family.id]
    }
    tandoor = {
      client_id           = "tandoor"
      name                = "Tandoor"
      launch_url          = "https://tandoor-recipes.haseebmajid.dev"
      callback_urls       = ["https://tandoor-recipes.haseebmajid.dev/accounts/oidc/pocket-id/login/callback/"]
      pkce_enabled        = false
      is_public           = false
      allowed_user_groups = [data.pocketid_group.family.id]
    }
    tinyauth = {
      client_id           = "tinyauth"
      name                = "TinyAuth"
      launch_url          = "https://auth.haseebmajid.dev"
      callback_urls       = ["https://auth.haseebmajid.dev/api/oauth/callback/pocketid"]
      pkce_enabled        = true
      is_public           = false
      allowed_user_groups = [data.pocketid_group.family.id]
    }
  }
}

resource "pocketid_client" "app" {
  for_each = local.oidc_apps

  client_id           = each.value.client_id
  name                = each.value.name
  launch_url          = each.value.launch_url
  callback_urls       = each.value.callback_urls
  pkce_enabled        = each.value.pkce_enabled
  is_public           = each.value.is_public
  allowed_user_groups = each.value.allowed_user_groups
}

# Groups / user / vault mount keep their existing addresses (no state moves).

resource "pocketid_group" "gotify_admins" {
  name          = "Gotify Admins"
  friendly_name = "Gotify Admins"
}

resource "pocketid_group" "grafana_admins" {
  name          = "Grafana Admins"
  friendly_name = "Grafana Admins"
}

resource "pocketid_group" "grafana_editors" {
  name          = "Grafana Editors"
  friendly_name = "Grafana Editors"
}

resource "pocketid_group" "jellyfin_admins" {
  name          = "jellyfin_admins"
  friendly_name = "Jellyfin Admins"
}

resource "pocketid_user" "hmajid2301" {
  username   = "hmajid2301"
  email      = "hello@haseebmajid.dev"
  first_name = "Haseeb"
  last_name  = "Majid"
  is_admin   = true
  disabled   = false
  groups = [
    data.pocketid_group.family.id,
    pocketid_group.gotify_admins.id,
    pocketid_group.grafana_admins.id,
    pocketid_group.jellyfin_admins.id,
  ]
}

resource "vault_mount" "kv" {
  path = "kv"
  type = "kv"
  options = {
    version = "2"
  }
}

# Stored OIDC credentials. Key = the old resource suffix minus `_oidc`.
locals {
  vault_oidc_apps = {
    goroutinely = true
    gothreads   = true
    immich      = true
    lettucego   = true
  }
}

resource "vault_kv_secret_v2" "oidc" {
  for_each = local.vault_oidc_apps

  mount = vault_mount.kv.path
  name  = "apps/${each.key}/oidc"
  data_json = jsonencode({
    client_id     = pocketid_client.app[each.key].id
    client_secret = pocketid_client.app[each.key].client_secret
  })
}

# Outputs keep their original names so any consumer keeps working.
output "goroutinely_client_id" {
  value = pocketid_client.app["goroutinely"].id
}

output "goroutinely_client_secret" {
  value     = pocketid_client.app["goroutinely"].client_secret
  sensitive = true
}

output "gotify_client_id" {
  value = pocketid_client.app["gotify"].id
}

output "gotify_client_secret" {
  value     = pocketid_client.app["gotify"].client_secret
  sensitive = true
}

output "dynacat_client_id" {
  value = pocketid_client.app["dynacat"].id
}

output "dynacat_client_secret" {
  value     = pocketid_client.app["dynacat"].client_secret
  sensitive = true
}

output "gothreads_client_id" {
  value = pocketid_client.app["gothreads"].id
}

output "gothreads_client_secret" {
  value     = pocketid_client.app["gothreads"].client_secret
  sensitive = true
}

output "grafana_client_id" {
  value = pocketid_client.app["grafana"].id
}

output "grafana_client_secret" {
  value     = pocketid_client.app["grafana"].client_secret
  sensitive = true
}

output "hister_client_id" {
  value = pocketid_client.app["hister"].id
}

output "hister_client_secret" {
  value     = pocketid_client.app["hister"].client_secret
  sensitive = true
}

output "immich_client_id" {
  value = pocketid_client.app["immich"].id
}

output "immich_client_secret" {
  value     = pocketid_client.app["immich"].client_secret
  sensitive = true
}

output "jellyfin_client_id" {
  value = pocketid_client.app["jellyfin"].id
}

output "jellyfin_client_secret" {
  value     = pocketid_client.app["jellyfin"].client_secret
  sensitive = true
}

output "karakeep_client_id" {
  value = pocketid_client.app["karakeep"].id
}

output "karakeep_client_secret" {
  value     = pocketid_client.app["karakeep"].client_secret
  sensitive = true
}

output "lettucego_client_id" {
  value = pocketid_client.app["lettucego"].id
}

output "lettucego_client_secret" {
  value     = pocketid_client.app["lettucego"].client_secret
  sensitive = true
}

output "papra_client_id" {
  value = pocketid_client.app["papra"].id
}

output "papra_client_secret" {
  value     = pocketid_client.app["papra"].client_secret
  sensitive = true
}

output "sure_client_id" {
  value = pocketid_client.app["sure"].id
}

output "sure_client_secret" {
  value     = pocketid_client.app["sure"].client_secret
  sensitive = true
}

output "tandoor_client_id" {
  value = pocketid_client.app["tandoor"].id
}

output "tandoor_client_secret" {
  value     = pocketid_client.app["tandoor"].client_secret
  sensitive = true
}

output "tinyauth_client_id" {
  value = pocketid_client.app["tinyauth"].id
}

output "tinyauth_client_secret" {
  value     = pocketid_client.app["tinyauth"].client_secret
  sensitive = true
}

output "grafana_admins_group_id" {
  value = pocketid_group.grafana_admins.id
}

output "grafana_editors_group_id" {
  value = pocketid_group.grafana_editors.id
}

output "hmajid2301_id" {
  value = pocketid_user.hmajid2301.id
}

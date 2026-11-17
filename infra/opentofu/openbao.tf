resource "vault_mount" "kv" {
  path = "kv"
  type = "kv"
  options = {
    version = "2"
  }
}

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

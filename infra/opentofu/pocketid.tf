data "pocketid_group" "family" {
  name = "family"
}

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
    forgejo = {
      client_id           = "forgejo"
      name                = "Forgejo"
      launch_url          = "https://forgejo.haseebmajid.dev"
      callback_urls       = ["https://forgejo.haseebmajid.dev/user/oauth2/pocketid/callback"]
      pkce_enabled        = false
      is_public           = false
      allowed_user_groups = [data.pocketid_group.family.id, pocketid_group.forgejo_admins.id]
    }
    goroutinely = {
      client_id           = "goroutinely"
      name                = "Goroutinely"
      launch_url          = "https://goroutinely.haseebmajid.dev"
      callback_urls       = ["https://goroutinely.haseebmajid.dev/callback"]
      pkce_enabled        = false
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
      allowed_user_groups = null
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
    umami = {
      client_id           = "umami"
      name                = "Umami"
      launch_url          = "https://umami.haseebmajid.dev"
      callback_urls       = ["https://umami.haseebmajid.dev/login/callback"]
      pkce_enabled        = false
      is_public           = false
      allowed_user_groups = [pocketid_group.umami_admins.id]
    }
    banter_quiz = {
      client_id           = "banter-quiz"
      name                = "Banter Quiz"
      launch_url          = "https://banterbus.haseebmajid.dev"
      callback_urls       = []
      pkce_enabled        = true
      is_public           = true
      allowed_user_groups = [pocketid_group.banterbus_admins.id]
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

resource "pocketid_group" "umami_admins" {
  name          = "umami_admins"
  friendly_name = "Umami Admins"
}

resource "pocketid_group" "forgejo_admins" {
  name          = "forgejo_admins"
  friendly_name = "Forgejo Admins"
}

resource "pocketid_group" "jellyfin_admins" {
  name          = "jellyfin_admins"
  friendly_name = "Jellyfin Admins"
}

resource "pocketid_group" "banterbus_admins" {
  name          = "banterbus_admins"
  friendly_name = "BanterBus Admins"
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
    pocketid_group.umami_admins.id,
    pocketid_group.forgejo_admins.id,
    pocketid_group.banterbus_admins.id,
  ]
}

provider "authentik" {
  url   = var.authentik_url
  token = var.authentik_token
}

# OAuth2 Provider for Karakeep
resource "authentik_provider_oauth2" "karakeep" {
  name               = "Provider for Karakeep"
  client_id          = "karakeep"
  authorization_flow = data.authentik_flow.default_authorization_flow.id
  invalidation_flow  = data.authentik_flow.default_invalidation_flow.id

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "https://karakeep.haseebmajid.dev/api/auth/callback/custom"
    }
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.ids[0],
    data.authentik_property_mapping_provider_scope.email.ids[0],
    data.authentik_property_mapping_provider_scope.profile.ids[0],
  ]

  signing_key = data.authentik_certificate_key_pair.default.id
}

# Application for Karakeep
resource "authentik_application" "karakeep" {
  name              = "Karakeep"
  slug              = "karakeep"
  protocol_provider = authentik_provider_oauth2.karakeep.id
}

# Data sources for existing Authentik resources
data "authentik_flow" "default_authorization_flow" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default_invalidation_flow" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_certificate_key_pair" "default" {
  name = "authentik Self-signed Certificate"
}

data "authentik_property_mapping_provider_scope" "openid" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid"
  ]
}

data "authentik_property_mapping_provider_scope" "email" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-email"
  ]
}

data "authentik_property_mapping_provider_scope" "profile" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-profile"
  ]
}

# Outputs for use in Karakeep configuration
output "karakeep_client_id" {
  value     = authentik_provider_oauth2.karakeep.client_id
  sensitive = false
}

output "karakeep_client_secret" {
  value     = authentik_provider_oauth2.karakeep.client_secret
  sensitive = true
}

output "karakeep_oauth_wellknown_url" {
  value = "https://${var.authentik_domain}/application/o/${authentik_application.karakeep.slug}/.well-known/openid-configuration"
}

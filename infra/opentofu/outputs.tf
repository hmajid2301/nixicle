output "oidc_client_ids" {
  value = { for k, c in pocketid_client.app : k => c.id }
}

output "oidc_client_secrets" {
  value     = { for k, c in pocketid_client.app : k => c.client_secret }
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

provider "desec" {
  api_token = var.desec_api_token
}

variable "desec_api_token" {
  description = "deSEC API token. Prefer DESEC_API_TOKEN env var or local terraform.tfvars."
  type        = string
  sensitive   = true
  nullable    = false
}

resource "desec_domain" "haseebmajid_dev" {
  name = "haseebmajid.dev"
}

resource "desec_records" "haseebmajid_dev" {
  domain    = desec_domain.haseebmajid_dev.name
  exclusive = true
  zonefile  = file("${path.module}/zones/haseebmajid.dev.zone")

  depends_on = [desec_domain.haseebmajid_dev]
}

data "desec_rrset" "haseebmajid_dev_nameservers" {
  domain  = desec_domain.haseebmajid_dev.name
  subname = "@"
  type    = "NS"
}

output "haseebmajid_dev_nameservers" {
  description = "Set these nameservers at the registrar after reviewing the OpenTofu apply."
  value       = data.desec_rrset.haseebmajid_dev_nameservers.rdata
}

output "haseebmajid_dev_ds_records" {
  description = "Set these DS records at the registrar when enabling DNSSEC delegation."
  value       = flatten([for key in desec_domain.haseebmajid_dev.keys : key.ds if key.managed])
}

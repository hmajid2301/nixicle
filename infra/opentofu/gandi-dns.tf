provider "gandi" {
  personal_access_token = var.gandi_personal_access_token
}

variable "gandi_personal_access_token" {
  description = "Gandi Personal Access Token. Prefer GANDI_PERSONAL_ACCESS_TOKEN env var or local terraform.tfvars."
  type        = string
  sensitive   = true
  nullable    = false
}

# LiveDNS zone for haseebmajid.dev.
# The domain must be registered with (or transferred to) Gandi before this
# resource can be created.  Gandi creates a LiveDNS zone automatically on
# transfer, so import this resource rather than creating it from scratch:
#
#   tofu import gandi_livedns_domain.haseebmajid_dev haseebmajid.dev
#
resource "gandi_livedns_domain" "haseebmajid_dev" {
  name = "haseebmajid.dev"
}

# ---------------------------------------------------------------------------
# A / AAAA records
# ---------------------------------------------------------------------------

resource "gandi_livedns_record" "apex_a" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "@"
  type   = "A"
  ttl    = 3600
  values = ["35.185.44.232"]
}

resource "gandi_livedns_record" "apex_aaaa" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "@"
  type   = "AAAA"
  ttl    = 3600
  values = ["2600:1901:0:7b8a::"]
}

resource "gandi_livedns_record" "wildcard_a" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "*"
  type   = "A"
  ttl    = 3600
  values = ["82.165.193.60"]
}

resource "gandi_livedns_record" "wildcard_aaaa" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "*"
  type   = "AAAA"
  ttl    = 3600
  values = ["2a00:da00:f478:c700::1"]
}

resource "gandi_livedns_record" "wildcard_homelab_a" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "*.homelab"
  type   = "A"
  ttl    = 3600
  values = ["100.96.71.17"]
}

resource "gandi_livedns_record" "wildcard_homelab_aaaa" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "*.homelab"
  type   = "AAAA"
  ttl    = 3600
  values = ["fd7a:115c:a1e0::4632:4712"]
}

resource "gandi_livedns_record" "talks_a" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "talks"
  type   = "A"
  ttl    = 3600
  values = ["35.185.44.232"]
}

# ---------------------------------------------------------------------------
# CNAME records
# ---------------------------------------------------------------------------

resource "gandi_livedns_record" "www_cname" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "www"
  type   = "CNAME"
  ttl    = 3600
  values = ["hmajid2301.gitlab.io."]
}

resource "gandi_livedns_record" "startpage_cname" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "startpage"
  type   = "CNAME"
  ttl    = 3600
  values = ["hmajid2301.github.io."]
}

resource "gandi_livedns_record" "stats_cname" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "stats"
  type   = "CNAME"
  ttl    = 3600
  values = ["haseebmajid.goatcounter.com."]
}

resource "gandi_livedns_record" "protonmail_dkim1" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "protonmail._domainkey"
  type   = "CNAME"
  ttl    = 3600
  values = ["protonmail.domainkey.dpe6jbu2ezg2se2h5zt6ulva555s5bjljx7y63lnh2xjxdl7c4zdq.domains.proton.ch."]
}

resource "gandi_livedns_record" "protonmail_dkim2" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "protonmail2._domainkey"
  type   = "CNAME"
  ttl    = 3600
  values = ["protonmail2.domainkey.dpe6jbu2ezg2se2h5zt6ulva555s5bjljx7y63lnh2xjxdl7c4zdq.domains.proton.ch."]
}

resource "gandi_livedns_record" "protonmail_dkim3" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "protonmail3._domainkey"
  type   = "CNAME"
  ttl    = 3600
  values = ["protonmail3.domainkey.dpe6jbu2ezg2se2h5zt6ulva555s5bjljx7y63lnh2xjxdl7c4zdq.domains.proton.ch."]
}

# ---------------------------------------------------------------------------
# MX records
# ---------------------------------------------------------------------------

resource "gandi_livedns_record" "apex_mx" {
  zone = gandi_livedns_domain.haseebmajid_dev.id
  name = "@"
  type = "MX"
  ttl  = 3600
  values = [
    "10 mail.protonmail.ch.",
    "20 mailsec.protonmail.ch.",
  ]
}

# ---------------------------------------------------------------------------
# TXT records
# ---------------------------------------------------------------------------

resource "gandi_livedns_record" "apex_txt" {
  zone = gandi_livedns_domain.haseebmajid_dev.id
  name = "@"
  type = "TXT"
  ttl  = 3600
  values = [
    "v=spf1 include:_spf.protonmail.ch ~all",
    "protonmail-verification=e5c36576cbb7c29adb533869365687b3673c88d4",
  ]
}

resource "gandi_livedns_record" "dmarc_txt" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "_dmarc"
  type   = "TXT"
  ttl    = 3600
  values = ["v=DMARC1; p=quarantine; rua=mailto:a20971b42d314803bb4de90264510943@dmarc-reports.cloudflare.net;"]
}

resource "gandi_livedns_record" "gitlab_pages_verification_txt" {
  zone   = gandi_livedns_domain.haseebmajid_dev.id
  name   = "_gitlab-pages-verification-code"
  type   = "TXT"
  ttl    = 3600
  values = ["gitlab-pages-verification-code=43458cdab5c97d1284f390edc5f60e3f"]
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

data "gandi_livedns_domain_ns" "haseebmajid_dev" {
  name = gandi_livedns_domain.haseebmajid_dev.name
}

output "haseebmajid_dev_nameservers" {
  description = "Gandi LiveDNS nameservers for haseebmajid.dev."
  value       = data.gandi_livedns_domain_ns.haseebmajid_dev.nameservers
}
provider "pocketid" {
  api_token = var.pocketid_api_token
  base_url  = var.pocketid_base_url
}

provider "vault" {
  address          = var.openbao_address
  skip_child_token = true
  token            = var.openbao_token
}

provider "gandi" {
  personal_access_token = var.gandi_personal_access_token
}

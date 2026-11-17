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

variable "gandi_personal_access_token" {
  description = "Gandi Personal Access Token. Prefer GANDI_PERSONAL_ACCESS_TOKEN env var or local terraform.tfvars."
  type        = string
  sensitive   = true
  nullable    = false
}

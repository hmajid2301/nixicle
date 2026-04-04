
variable "remote_state_address" {
  type        = string
  description = "Gitlab remote state file address"
}

variable "username" {
  type        = string
  description = "Gitlab username to query remote state"
}

variable "access_token" {
  type        = string
  description = "GitLab access token to query remote state"
}

variable "authentik_url" {
  type        = string
  description = "Authentik instance URL"
  default     = "https://authentik.haseebmajid.dev"
}

variable "authentik_token" {
  type        = string
  description = "Authentik API token"
  sensitive   = true
}

variable "authentik_domain" {
  type        = string
  description = "Authentik domain for OAuth URLs"
  default     = "authentik.haseebmajid.dev"
}

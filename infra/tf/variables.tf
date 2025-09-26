
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

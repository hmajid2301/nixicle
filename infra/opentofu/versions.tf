terraform {
  backend "http" {}

  required_providers {
    pocketid = {
      source  = "trozz/pocketid"
      version = "~> 2.3"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
    gandi = {
      source  = "go-gandi/gandi"
      version = "~> 2.3"
    }
  }
  required_version = ">= 1.0"
}

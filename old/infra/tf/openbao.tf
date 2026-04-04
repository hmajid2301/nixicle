terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    betterstack = {
      source  = "BetterStackHQ/better-uptime"
      version = "~> 0.9.0"
    }
    logtail = {
      source  = "BetterStackHQ/logtail"
      version = "~> 0.3.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2024.12.1"
    }
  }
}

variable "openbao_address" {
  description = "OpenBao server address"
  type        = string
  default     = "https://openbao.homelab.haseebmajid.dev"
}

variable "openbao_token" {
  description = "OpenBao authentication token"
  type        = string
  sensitive   = true
}

variable "postgres_terraform_password" {
  description = "Password for postgres terraform user (from SOPS)"
  type        = string
  sensitive   = true
}

variable "postgres_host" {
  description = "Postgres host"
  type        = string
  default     = "postgres.homelab.haseebmajid.dev"
}

variable "postgres_port" {
  description = "Postgres port"
  type        = number
  default     = 5433
}

variable "tofu_user_password" {
  description = "Password for tofu userpass user"
  type        = string
  sensitive   = true
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubernetes_host" {
  description = "Kubernetes API server endpoint (optional, will be auto-detected if not provided)"
  type        = string
  default     = ""
}

provider "vault" {
  address = var.openbao_address
  token   = var.openbao_token
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

# Import existing auth backends
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "kubernetes"
}

resource "vault_auth_backend" "userpass" {
  type = "userpass"
  path = "userpass"
}

resource "vault_auth_backend" "approle" {
  type = "approle"
  path = "approle"
}

# Get Kubernetes cluster info dynamically
data "kubernetes_config_map" "kube_root_ca" {
  metadata {
    name      = "kube-root-ca.crt"
    namespace = "kube-public"
  }
}

# Get cluster endpoint from nodes or service
data "kubernetes_nodes" "all" {}

# Use existing service account for vault authentication
data "kubernetes_service_account_v1" "vault_auth" {
  metadata {
    name      = "vault-auth"
    namespace = "kube-system"
  }
}

# Create token for the existing service account
resource "kubernetes_secret_v1" "vault_auth_token" {
  metadata {
    name      = "vault-auth-token"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = data.kubernetes_service_account_v1.vault_auth.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}

# Kubernetes auth configuration
resource "vault_kubernetes_auth_backend_config" "kubernetes" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://vps:6443"
  kubernetes_ca_cert     = data.kubernetes_config_map.kube_root_ca.data["ca.crt"]
  token_reviewer_jwt     = kubernetes_secret_v1.vault_auth_token.data["token"]
  disable_iss_validation = true
  disable_local_ca_jwt   = true
}

# Kubernetes auth roles
resource "vault_kubernetes_auth_backend_role" "k8s_auth_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "k8s-auth-role"
  bound_service_account_names      = ["default", "banterbus", "openbao-auth", "flux-system-vault", "gitlab-agent"]
  bound_service_account_namespaces = ["infra", "flux-system", "default", "prod", "dev", "apps", "tailscale", "gitlab-agent-k8s"]
  token_policies                   = ["default", "banterbus-dev", "banterbus-prod", "gitlab", "gitlab-agent"]
  token_ttl                        = 3600
  token_max_ttl                    = 86400
}

resource "vault_kubernetes_auth_backend_role" "tailscale" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "tailscale"
  bound_service_account_names      = ["tailscale"]
  bound_service_account_namespaces = ["tailscale"]
  token_policies                   = ["tailscale"]
  token_ttl                        = 3600
}

# Userpass users
resource "vault_generic_endpoint" "tofu_user" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/tofu"
  ignore_absent_fields = true

  data_json = jsonencode({
    policies = ["tofu", "cloudflare-tunnel"]
    password = var.tofu_user_password
  })
}

# Additional policy - test-csi-policy
resource "vault_policy" "test_csi" {
  name = "test-csi-policy"

  policy = <<EOT
path "kv/data/apps/dev/banterbus" {
  capabilities = ["read"]
}

path "kv/metadata/apps/dev/banterbus" {
  capabilities = ["read"]
}
EOT
}

# Import existing policies
resource "vault_policy" "cloudflare_tunnel" {
  name = "cloudflare-tunnel"

  policy = <<EOT
# Allow full access to cloudflare tunnel secrets
path "kv/data/infra/cloudflare" {
  capabilities = ["create", "read", "update", "delete"]
}

path "kv/metadata/infra/cloudflare" {
  capabilities = ["read", "list"]
}

# Allow reading tunnel token for Kubernetes deployment
path "kv/data/infra/cloudflare" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "banterbus_dev" {
  name = "banterbus-dev"

  policy = <<EOT
# Allow reading banterbus dev secrets
path "kv/data/apps/dev/banterbus" {
  capabilities = ["read"]
}

path "kv/metadata/apps/dev/banterbus" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "banterbus_prod" {
  name = "banterbus-prod"

  policy = <<EOT
# Allow reading banterbus prod secrets
path "kv/data/apps/prod/banterbus" {
  capabilities = ["read"]
}

path "kv/metadata/apps/prod/banterbus" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "tailscale" {
  name = "tailscale"

  policy = <<EOT
path "kv/data/infra/tailscale" {
  capabilities = ["read"]
}

path "kv/metadata/infra/tailscale" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "gitlab" {
  name = "gitlab"

  policy = <<EOT
# Allow reading GitLab secrets for flux preview environments
path "kv/data/apps/gitlab" {
  capabilities = ["read"]
}

path "kv/metadata/apps/gitlab" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "gitlab_agent" {
  name = "gitlab-agent"

  policy = <<EOT
# Allow reading GitLab agent token
path "kv/data/infra/gitlab" {
  capabilities = ["read"]
}

path "kv/metadata/infra/gitlab" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "tofu" {
  name = "tofu"

  policy = <<EOT
path "kv/*" {
  capabilities = ["list"]
}

path "kv/data/apps/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "kv/data/infra/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "kv/metadata/apps/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "kv/metadata/infra/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "sys/auth/kubernetes" {
  capabilities = ["create", "read", "update", "delete"]
}

path "sys/mounts/*" {
  capabilities = ["read", "list"]
}

path "sys/mounts" {
  capabilities = ["read", "list"]
}

path "auth/kubernetes" {
  capabilities = ["read"]
}

path "auth/kubernetes/config" {
  capabilities = ["create", "read", "update", "delete"]
}

path "auth/kubernetes/role/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "sys/auth" {
  capabilities = ["read", "list"]
}

path "sys/auth/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "auth/token/create" {
  capabilities = ["create", "update"]
}
EOT
}

# Secret engines
resource "vault_mount" "kv" {
  path = "kv"
  type = "kv"
  options = {
    version = "2"
  }
  description = "KV v2 secret mount"
}

resource "vault_mount" "spindle" {
  path = "spindle"
  type = "kv"
  options = {
    version = "2"
  }
  description = "KV v2 secret mount for Spindle"
}

resource "vault_mount" "kubernetes" {
  path        = "kubernetes"
  type        = "kubernetes"
  description = "Kubernetes secret engine"
}

# TODO: move to name tofu
# Create postgres terraform user secret
resource "vault_kv_secret_v2" "postgres_terraform" {
  mount = vault_mount.kv.path
  name  = "infra/postgres/terraform"

  data_json = jsonencode({
    username = "terraform"
    password = var.postgres_terraform_password
    host     = var.postgres_host
    port     = var.postgres_port
  })
}

# Policy for postgres terraform access
resource "vault_policy" "postgres_terraform" {
  name = "postgres-terraform"

  policy = <<EOT
path "kv/data/infra/postgres/terraform" {
  capabilities = ["read"]
}

path "kv/metadata/infra/postgres/terraform" {
  capabilities = ["read"]
}
EOT
}

# Create ClusterRoleBinding for token review
resource "kubernetes_cluster_role_binding_v1" "vault_auth_delegator" {
  metadata {
    name = "vault-auth-delegator"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = data.kubernetes_service_account_v1.vault_auth.metadata[0].name
    namespace = data.kubernetes_service_account_v1.vault_auth.metadata[0].namespace
  }
}

resource "vault_policy" "spindle" {
  name = "spindle-policy"

  policy = <<EOT
path "spindle/data/*" {
  capabilities = ["create", "read", "update", "delete"]
}

path "spindle/metadata/*" {
  capabilities = ["list", "read", "delete", "update"]
}

path "spindle/" {
  capabilities = ["list"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOT
}

resource "vault_approle_auth_backend_role" "spindle" {
  backend        = vault_auth_backend.approle.path
  role_name      = "spindle"
  token_policies = [vault_policy.spindle.name]
  token_ttl      = 3600
  token_max_ttl  = 14400
  bind_secret_id = true
  secret_id_ttl  = 0
}

output "spindle_role_id" {
  value       = vault_approle_auth_backend_role.spindle.role_id
  sensitive   = false
}

resource "vault_approle_auth_backend_role_secret_id" "spindle" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.spindle.role_name
}

output "spindle_secret_id" {
  value       = vault_approle_auth_backend_role_secret_id.spindle.secret_id
  sensitive   = true
}

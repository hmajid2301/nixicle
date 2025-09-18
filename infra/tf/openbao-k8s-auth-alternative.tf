# Alternative approach using a service account for OpenBao

# Create a service account for OpenBao to use
resource "kubernetes_service_account" "vault_auth" {
  metadata {
    name      = "vault-auth"
    namespace = "kube-system"
  }
}

# Create a secret for the service account (K8s 1.24+)
resource "kubernetes_secret" "vault_auth_token" {
  metadata {
    name      = "vault-auth-token"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.vault_auth.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}

# Give the service account permissions to verify tokens
resource "kubernetes_cluster_role_binding" "vault_auth" {
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
    name      = kubernetes_service_account.vault_auth.metadata[0].name
    namespace = kubernetes_service_account.vault_auth.metadata[0].namespace
  }
}

# Use this configuration instead:
# resource "vault_kubernetes_auth_backend_config" "kubernetes" {
#   backend                = vault_auth_backend.kubernetes.path
#   kubernetes_host        = local.kubernetes_host
#   kubernetes_ca_cert     = data.kubernetes_config_map.kube_root_ca.data["ca.crt"]
#   token_reviewer_jwt     = kubernetes_secret.vault_auth_token.data.token
#   disable_iss_validation = true
#   disable_local_ca_jwt   = false
# }
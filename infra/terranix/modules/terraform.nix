{
  terraform = {
    required_version = ">= 1.0";
    backend.local = { };

    required_providers = {
      pocketid = {
        source = "trozz/pocketid";
        version = "~> 0.1";
      };
      vault = {
        source = "hashicorp/vault";
        version = "~> 4.0";
      };
    };
  };

  provider.pocketid = {
    base_url = "\${var.pocketid_base_url}";
    api_token = "\${var.pocketid_api_token}";
  };

  provider.vault = {
    address = "\${var.openbao_address}";
    token = "\${var.openbao_token}";
    skip_child_token = true;
  };

  variable.pocketid_base_url = {
    type = "string";
    description = "Pocket-ID base URL, e.g. https://id.haseebmajid.dev";
  };

  variable.pocketid_api_token = {
    type = "string";
    description = "Pocket-ID admin API token";
    sensitive = true;
  };

  variable.openbao_address = {
    type = "string";
    description = "OpenBao/Vault API URL.";
    default = "https://openbao.homelab.haseebmajid.dev";
  };

  variable.openbao_token = {
    type = "string";
    description = "OpenBao/Vault token used by the Vault provider.";
    sensitive = true;
  };
}

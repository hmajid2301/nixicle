{
  terraform = {
    required_version = ">= 1.0";
    backend.http = { };

    required_providers = {
      pocketid = {
        source = "trozz/pocketid";
        version = "~> 0.1";
      };
    };
  };

  provider.pocketid = {
    base_url = "\${var.pocketid_base_url}";
    api_token = "\${var.pocketid_api_token}";
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
}

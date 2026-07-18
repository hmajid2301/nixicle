let
  apps = [
    "goroutinely"
    "gothreads"
    "lettucego"
  ];

  mkSecret = app: {
    resource.vault_kv_secret_v2."${app}_oidc" = {
      mount = "\${vault_mount.kv.path}";
      name = "apps/${app}/oidc";
      data_json = builtins.toJSON {
        client_id = "\${pocketid_client.${app}.id}";
        client_secret = "\${pocketid_client.${app}.client_secret}";
      };
    };
  };
in
{
  resource.vault_mount.kv = {
    path = "kv";
    type = "kv";
    options.version = "2";
  };

  imports = map mkSecret apps;
}

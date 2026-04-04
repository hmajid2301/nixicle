let
  defaultEmail = "haseeb@haseebmajid.dev";
  defaultSigningKey = "key::ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOqSgMNy4nomfzGHVLt9GNAM02kP2CWrjU+O3CdN0dt5";
  defaultAuthorizedKeys = [ defaultSigningKey ];
in
{
  den.schema.user = { lib, ... }: {
    options = {
      email = lib.mkOption {
        type = lib.types.str;
        default = defaultEmail;
      };
      signingKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = defaultSigningKey;
      };
      authorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = defaultAuthorizedKeys;
      };
    };
  };

  den.schema.home = { lib, ... }: {
    options = {
      email = lib.mkOption {
        type = lib.types.str;
        default = defaultEmail;
      };
      signingKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = defaultSigningKey;
      };
    };
  };
}

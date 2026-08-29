_: {
  den.aspects.server-admin = {
    nixos =
      {
        config,
        lib,
        ...
      }:
      let
        cfg = config.nixicle.serverAdmin;
      in
      {
        options.nixicle.serverAdmin = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to configure a shared server admin user and root SSH keys.";
          };

          userName = lib.mkOption {
            type = lib.types.str;
            default = "nixos";
            description = "Name of the primary server admin user.";
          };

          authorizedKeys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "SSH public keys installed for both root and the server admin user.";
          };

          extraGroups = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "wheel" ];
            description = "Extra groups for the server admin user.";
          };

          uid = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            description = "Optional UID for the server admin user.";
          };

          mediaGid = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            description = "Optional gid to assign to the shared media group.";
          };

          mutableUsers = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether users.mutableUsers should be enabled.";
          };

          initialPassword = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional initial password for the server admin user.";
          };

          hashedPasswordFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional hashedPasswordFile for the server admin user.";
          };

          shell = lib.mkOption {
            type = lib.types.nullOr lib.types.package;
            default = null;
            description = "Optional shell for the server admin user.";
          };

          sudo.execWheelOnly = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "Optional execWheelOnly value for security.sudo.";
          };

          sudo.wheelNeedsPassword = lib.mkOption {
            type = lib.types.nullOr lib.types.bool;
            default = null;
            description = "Optional wheelNeedsPassword value for security.sudo.";
          };
        };

        config = lib.mkIf cfg.enable {
          users = {
            inherit (cfg) mutableUsers;
            groups.media = lib.mkIf (cfg.mediaGid != null) { gid = cfg.mediaGid; };
            users.root.openssh.authorizedKeys.keys = cfg.authorizedKeys;
            users.${cfg.userName} = {
              isNormalUser = true;
              group = "users";
              inherit (cfg) extraGroups;
              openssh.authorizedKeys.keys = cfg.authorizedKeys;
            }
            // lib.optionalAttrs (cfg.shell != null) {
              inherit (cfg) shell;
            }
            // lib.optionalAttrs (cfg.uid != null) {
              inherit (cfg) uid;
            }
            // lib.optionalAttrs (cfg.initialPassword != null) {
              inherit (cfg) initialPassword;
            }
            // lib.optionalAttrs (cfg.hashedPasswordFile != null) {
              inherit (cfg) hashedPasswordFile;
            };
          };

          security.sudo =
            { }
            // lib.optionalAttrs (cfg.sudo.execWheelOnly != null) {
              execWheelOnly = cfg.sudo.execWheelOnly;
            }
            // lib.optionalAttrs (cfg.sudo.wheelNeedsPassword != null) {
              wheelNeedsPassword = cfg.sudo.wheelNeedsPassword;
            };
        };
      };
  };
}

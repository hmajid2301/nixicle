{ lib, ... }:
{
  options.nixicle = {
    domains = {
      root = lib.mkOption {
        type = lib.types.str;
        default = lib.nixicle.domains.root;
        description = "Primary public domain.";
      };
      homelab = lib.mkOption {
        type = lib.types.str;
        default = lib.nixicle.domains.homelab;
        description = "Homelab service domain (routed over the tailnet).";
      };
      sso = lib.mkOption {
        type = lib.types.str;
        default = lib.nixicle.domains.sso;
        description = "Identity provider domain.";
      };
    };
    identity.adminEmail = lib.mkOption {
      type = lib.types.str;
      default = lib.nixicle.adminEmail;
      description = "Admin contact email (ACME, notifications, mail from).";
    };
  };
}

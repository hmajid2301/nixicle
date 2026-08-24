{ config, lib, ... }:
let
  http = config.services.traefik.dynamicConfigOptions.http or { };
  routers = http.routers or { };
  traefikServices = http.services or { };
in
rec {
  parseHost = rule:
    let
      m = builtins.match "^Host\\(`([^`]+)`\\).*" rule;
    in
    if m == null then null else "https://${builtins.head m}";

  publicUrl = name: parseHost ((routers.${name} or { }).rule or "");

  internalUrl = name:
    let
      svc = traefikServices.${name} or { };
      servers = svc.loadBalancer.servers or [ ];
      first = builtins.head servers;
    in
    if servers == [ ] then null else first.url or null;

  hrefOr = name: fallback:
    let p = publicUrl name; in if p != null then p else fallback;

  serviceEnabled = path: (lib.attrByPath path false config) == true;

  unitEnabled = name:
    let unit = config.systemd.services.${name} or { }; in
    (unit.enable or true) != false && (unit.wantedBy or [ ]) != [ ];

  cleanWidget = w: lib.filterAttrs (_: v: v != null) w;

  mkHomepageService =
    { name
    , icon
    , description
    , enable
    , href
    , widget ? null
    }:
    lib.optional enable [
      {
        ${name} = {
          inherit icon description href;
        } // lib.optionalAttrs (widget != null) {
          widget = cleanWidget widget;
        };
      }
    ];
}

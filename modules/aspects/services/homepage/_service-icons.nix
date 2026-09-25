{
  lib ? null,
  pkgs ? null,
}:
rec {
  iconsUrl = "https://homepage.${lib.nixicle.domains.root}/icons";

  slugs = {
    Tandoor = "tandoor";
    Papra = "papra";
    Karakeep = "karakeep";
    BanterBus = "banterbus";
    Goroutinely = "goroutinely";
    LettuceGo = "lettucego";
    Immich = "immich";
    Jellyfin = "jellyfin";
    Forgejo = "forgejo";
    Traefik = "traefik";
    PocketID = "pocket-id";
    HomeAssistant = "home-assistant";
    Grafana = "grafana";
    Prometheus = "prometheus";
  };

  renderIcon = body: ''
    <svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32' shape-rendering='crispEdges'>
      <rect width='32' height='32' fill='rgb(24,24,37)'/>
      ${body}
    </svg>
  '';

  pixelArt = {
    Tandoor = renderIcon ''
      <rect x='6' y='10' width='20' height='12' fill='rgb(180,107,74)'/>
      <rect x='8' y='12' width='16' height='8' fill='rgb(249,226,175)'/>
      <rect x='12' y='6' width='8' height='3' fill='rgb(137,180,250)'/>
      <rect x='7' y='23' width='18' height='2' fill='rgb(245,194,231)'/>
    '';
    Papra = renderIcon ''
      <rect x='7' y='5' width='18' height='22' fill='rgb(205,214,244)'/>
      <rect x='20' y='5' width='5' height='5' fill='rgb(147,153,178)'/>
      <rect x='10' y='11' width='10' height='2' fill='rgb(137,180,250)'/>
      <rect x='10' y='15' width='8' height='2' fill='rgb(137,180,250)'/>
      <rect x='10' y='19' width='6' height='2' fill='rgb(137,180,250)'/>
    '';
    Karakeep = renderIcon ''
      <rect x='8' y='5' width='16' height='22' fill='rgb(245,194,231)'/>
      <rect x='10' y='7' width='12' height='18' fill='rgb(205,214,244)'/>
      <rect x='14' y='6' width='4' height='6' fill='rgb(243,139,168)'/>
      <rect x='13' y='20' width='6' height='4' fill='rgb(243,139,168)'/>
    '';
    BanterBus = renderIcon ''
      <rect x='5' y='11' width='22' height='10' fill='rgb(249,226,175)'/>
      <rect x='7' y='13' width='18' height='4' fill='rgb(137,180,250)'/>
      <rect x='8' y='21' width='4' height='4' fill='rgb(147,153,178)'/>
      <rect x='20' y='21' width='4' height='4' fill='rgb(147,153,178)'/>
      <rect x='12' y='8' width='8' height='3' fill='rgb(245,194,231)'/>
    '';
    Goroutinely = renderIcon ''
      <rect x='12' y='6' width='8' height='20' fill='rgb(137,180,250)'/>
      <rect x='6' y='12' width='20' height='8' fill='rgb(137,180,250)'/>
      <rect x='13' y='9' width='6' height='14' fill='rgb(24,24,37)'/>
      <rect x='9' y='5' width='4' height='4' fill='rgb(249,226,175)'/>
      <rect x='19' y='5' width='4' height='4' fill='rgb(249,226,175)'/>
      <rect x='9' y='23' width='4' height='4' fill='rgb(249,226,175)'/>
      <rect x='19' y='23' width='4' height='4' fill='rgb(249,226,175)'/>
    '';
    LettuceGo = renderIcon ''
      <rect x='15' y='5' width='2' height='22' fill='rgb(245,194,231)'/>
      <rect x='9' y='9' width='6' height='4' fill='rgb(166,227,161)'/>
      <rect x='11' y='13' width='8' height='4' fill='rgb(166,227,161)'/>
      <rect x='9' y='17' width='6' height='4' fill='rgb(166,227,161)'/>
      <rect x='17' y='11' width='6' height='4' fill='rgb(166,227,161)'/>
      <rect x='17' y='15' width='6' height='4' fill='rgb(166,227,161)'/>
    '';
    Immich = renderIcon ''
      <rect x='6' y='9' width='20' height='14' fill='rgb(147,153,178)'/>
      <rect x='9' y='7' width='6' height='3' fill='rgb(205,214,244)'/>
      <rect x='13' y='12' width='6' height='6' fill='rgb(137,180,250)'/>
      <rect x='15' y='14' width='2' height='2' fill='rgb(24,24,37)'/>
      <rect x='21' y='11' width='2' height='2' fill='rgb(245,194,231)'/>
    '';
    Jellyfin = renderIcon ''
      <rect x='9' y='8' width='14' height='2' fill='rgb(203,166,247)'/>
      <rect x='8' y='10' width='16' height='6' fill='rgb(203,166,247)'/>
      <rect x='10' y='16' width='2' height='8' fill='rgb(180,190,254)'/>
      <rect x='14' y='16' width='2' height='10' fill='rgb(180,190,254)'/>
      <rect x='18' y='16' width='2' height='7' fill='rgb(180,190,254)'/>
      <rect x='12' y='12' width='2' height='2' fill='rgb(24,24,37)'/>
      <rect x='18' y='12' width='2' height='2' fill='rgb(24,24,37)'/>
    '';
    Forgejo = renderIcon ''
      <rect x='9' y='8' width='4' height='4' fill='rgb(203,166,247)'/>
      <rect x='19' y='8' width='4' height='4' fill='rgb(203,166,247)'/>
      <rect x='14' y='18' width='4' height='4' fill='rgb(203,166,247)'/>
      <rect x='11' y='10' width='8' height='2' fill='rgb(137,180,250)'/>
      <rect x='15' y='12' width='2' height='6' fill='rgb(137,180,250)'/>
    '';
    Traefik = renderIcon ''
      <rect x='6' y='18' width='20' height='4' fill='rgb(137,180,250)'/>
      <rect x='9' y='10' width='4' height='8' fill='rgb(245,194,231)'/>
      <rect x='15' y='7' width='4' height='11' fill='rgb(245,194,231)'/>
      <rect x='21' y='13' width='4' height='5' fill='rgb(245,194,231)'/>
      <rect x='13' y='6' width='2' height='2' fill='rgb(249,226,175)'/>
    '';
    PocketID = renderIcon ''
      <rect x='6' y='7' width='20' height='18' fill='rgb(249,226,175)'/>
      <rect x='8' y='9' width='16' height='14' fill='rgb(205,214,244)'/>
      <rect x='11' y='12' width='10' height='2' fill='rgb(137,180,250)'/>
      <rect x='11' y='16' width='6' height='2' fill='rgb(137,180,250)'/>
      <rect x='18' y='15' width='3' height='4' fill='rgb(24,24,37)'/>
    '';
    HomeAssistant = renderIcon ''
      <rect x='8' y='14' width='16' height='10' fill='rgb(243,139,168)'/>
      <rect x='10' y='10' width='12' height='6' fill='rgb(245,194,231)'/>
      <rect x='12' y='7' width='8' height='4' fill='rgb(137,180,250)'/>
      <rect x='12' y='16' width='8' height='8' fill='rgb(205,214,244)'/>
      <rect x='15' y='18' width='2' height='2' fill='rgb(24,24,37)'/>
    '';
    Grafana = renderIcon ''
      <rect x='8' y='8' width='16' height='16' fill='rgb(249,226,175)'/>
      <rect x='10' y='10' width='12' height='12' fill='rgb(24,24,37)'/>
      <rect x='15' y='9' width='2' height='8' fill='rgb(243,139,168)'/>
      <rect x='12' y='17' width='8' height='2' fill='rgb(137,180,250)'/>
      <rect x='12' y='20' width='8' height='2' fill='rgb(245,194,231)'/>
    '';
    Prometheus = renderIcon ''
      <rect x='10' y='6' width='12' height='4' fill='rgb(243,139,168)'/>
      <rect x='8' y='10' width='16' height='6' fill='rgb(249,226,175)'/>
      <rect x='10' y='16' width='12' height='6' fill='rgb(180,107,74)'/>
      <rect x='12' y='12' width='8' height='8' fill='rgb(243,139,168)'/>
      <rect x='14' y='13' width='4' height='4' fill='rgb(24,24,37)'/>
    '';
  };

  favicon = renderIcon ''
    <rect x='4' y='7' width='24' height='3' fill='rgb(243,139,168)'/>
    <rect x='6' y='10' width='20' height='3' fill='rgb(243,139,168)'/>
    <rect x='8' y='13' width='16' height='3' fill='rgb(243,139,168)'/>
    <rect x='7' y='16' width='18' height='11' fill='rgb(183,189,248)'/>
    <rect x='13' y='20' width='6' height='7' fill='rgb(30,30,46)'/>
    <rect x='11' y='18' width='3' height='2' fill='rgb(249,226,175)'/>
  '';

  serviceIcons = builtins.mapAttrs (name: _: "${iconsUrl}/${slugs.${name}}.svg") pixelArt;

  iconsPackage = pkgs.symlinkJoin {
    name = "homepage-icons";
    paths =
      (lib.mapAttrsToList (
        name: _: pkgs.writeTextDir "icons/${slugs.${name}}.svg" (renderIcon pixelArt.${name})
      ) pixelArt)
      ++ [ (pkgs.writeTextDir "icons/favicon.svg" favicon) ];
  };
}

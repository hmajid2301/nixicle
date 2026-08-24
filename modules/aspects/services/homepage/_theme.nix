# Pixel / retro homepage theme CSS
# Provides 8-bit-game variants plus a CRT and Synthwave variant.
{ }:
let
  # ------------------------------------------------------------------
  # Assets
  # ------------------------------------------------------------------
  assets = import ./_pixel-assets.nix;

  heroFor =
    paletteName:
    let
      prefix = if paletteName == "catppuccin" then "cat" else paletteName;
    in
    assets.${paletteName}."icon-${prefix}-hero";

  # ------------------------------------------------------------------
  # Palettes
  # ------------------------------------------------------------------
  navy = {
    bg = "20 29 53"; # #141D35
    surface = "24 35 73"; # #182349
    surface2 = "29 40 59"; # #1D283B
    elevated = "53 68 115"; # #354473
    border = "78 94 148"; # #4E5E94
    accent = "83 217 240"; # #53D9F0
    accent2 = "78 188 216"; # #4EBCD8
    gold = "244 222 107"; # #F4DE6B
    text = "242 243 231"; # #F2F3E7
    muted = "172 185 192"; # #ACB9C0
    danger = "184 107 74"; # #B86B4A
    good = "125 196 127"; # #7DC47F
    black = "0 0 0";
    white = "255 255 255";
  };

  catppuccin = {
    bg = "30 30 46"; # #1E1E2E
    surface = "24 24 37"; # #181825
    surface2 = "49 50 68"; # #313244
    elevated = "69 71 90"; # #45475A
    border = "88 91 112"; # #585B70
    accent = "137 180 250"; # #89B4FA
    accent2 = "245 194 231"; # #F5C2E7
    gold = "249 226 175"; # #F9E2AF
    text = "205 214 244"; # #CDD6F4
    muted = "147 153 178"; # #9399B2
    danger = "243 139 168"; # #F38BA8
    good = "166 227 161"; # #A6E3A1
    black = "0 0 0";
    white = "255 255 255";
  };

  googleFonts = ''
    @import url('https://fonts.googleapis.com/css2?family=Press+Start+2P&family=VT323&family=JetBrains+Mono:wght@400;700&display=swap');
  '';

  # Override Tailwind semantic colors in dark mode.
  colorsFor = palette: ''
    .dark.theme-slate,
    .dark.theme-slate #__next {
      --color-50:  ${palette.text};
      --color-100: ${palette.text};
      --color-200: ${palette.muted};
      --color-300: ${palette.border};
      --color-400: ${palette.accent};
      --color-500: ${palette.gold};
      --color-600: ${palette.elevated};
      --color-700: ${palette.surface2};
      --color-800: ${palette.surface};
      --color-900: ${palette.bg};
      --color-logo-start: ${palette.accent};
      --color-logo-stop: ${palette.gold};
    }
  '';

  scanlinesFor = palette: ''
    .dark.theme-slate::before {
      content: "";
      position: fixed;
      inset: 0;
      z-index: 9999;
      pointer-events: none;
      background: repeating-linear-gradient(
        to bottom,
        rgba(0,0,0,0) 0px,
        rgba(0,0,0,0) 2px,
        rgba(0,0,0,0.18) 3px,
        rgba(0,0,0,0) 4px
      );
      mix-blend-mode: multiply;
    }
    .dark.theme-slate::after {
      content: "";
      position: fixed;
      inset: 0;
      z-index: 9998;
      pointer-events: none;
      background: radial-gradient(ellipse at center, transparent 55%, rgba(0,0,0,0.45) 100%);
    }
  '';

  glowFor = palette: ''
    .dark.theme-slate h1,
    .dark.theme-slate h2,
    .dark.theme-slate h3,
    .dark.theme-slate h4,
    .dark.theme-slate .text-theme-400,
    .dark.theme-slate [class*="text-theme-400"] {
      text-shadow: 0 0 6px rgba(${palette.accent}, 0.55), 0 0 14px rgba(${palette.accent}, 0.25);
    }
  '';

  # ------------------------------------------------------------------
  # Pixel-art icon injection (service + group icons)
  # ------------------------------------------------------------------
  pixelIconsFor =
    paletteName:
    let
      prefix = if paletteName == "catppuccin" then "cat" else paletteName;
      a = assets.${paletteName};
      icon = name: "url(${a.${"icon-${prefix}-${name}"}})";
      groupIcon = group: ''
        .dark.theme-slate .services-group[data-pixel-group="${group}"] .service-group-name::before,
        .dark.theme-slate .services-group[data-pixel-group="${group}"] button.service-group-name::before {
          background-image: ${icon group};
        }
      '';
    in
    ''
      /* Service images are actual embedded pixel SVGs from the service list. */
      .dark.theme-slate .service-icon {
        position: relative !important;
      }
      .dark.theme-slate .service-icon img,
      .dark.theme-slate .service-icon svg {
        width: 100% !important;
        height: 100% !important;
        max-width: 100% !important;
        max-height: 100% !important;
        object-fit: contain !important;
        image-rendering: pixelated !important;
      }

      /* Hide the default group icon image and inject our own sprite into the group name */
      .dark.theme-slate .service-group-icon {
        display: none !important;
      }

      /* Group header gets a leading pixel icon */
      .dark.theme-slate .services-group[data-pixel-group] .service-group-name::before,
      .dark.theme-slate .services-group[data-pixel-group] button.service-group-name::before {
        content: "";
        display: block;
        width: 24px;
        height: 24px;
        margin-right: 0.55rem;
        flex-shrink: 0;
        background-size: contain;
        background-repeat: no-repeat;
        background-position: center;
        image-rendering: pixelated;
      }

      ${groupIcon "external"}
      ${groupIcon "internal"}
      ${groupIcon "media"}
      ${groupIcon "monitoring"}
      ${groupIcon "disk"}
      ${groupIcon "network"}
    '';

  decorClassesFor =
    paletteName:
    let
      prefix = if paletteName == "catppuccin" then "cat" else paletteName;
      a = assets.${paletteName};
      mkClass = name: key: ''
        .${name} {
          background-image: url(${a.${key}});
        }
      '';
    in
    ''
      /* Scattered decorative pixel sprites */
      .parpa-scatter {
        position: fixed;
        pointer-events: none;
        z-index: 0;
        background-repeat: no-repeat;
        background-position: center;
        image-rendering: pixelated;
        opacity: 0.7;
      }
      .parpa-scatter-sm { width: 48px; height: 48px; background-size: 48px 48px; }
      .parpa-scatter-md { width: 72px; height: 72px; background-size: 72px 72px; }
      .parpa-scatter-lg { width: 96px; height: 96px; background-size: 96px 96px; }
      .parpa-scatter-xl { width: 128px; height: 128px; background-size: 128px 128px; }
      ${mkClass "parpa-decor-moon" "icon-${prefix}-decor-moon"}
      ${mkClass "parpa-decor-cloud" "icon-${prefix}-decor-cloud"}
      ${mkClass "parpa-decor-potted-plant" "icon-${prefix}-decor-potted-plant"}
      ${mkClass "parpa-decor-watering-can" "icon-${prefix}-decor-watering-can"}
      ${mkClass "parpa-decor-fork" "icon-${prefix}-decor-fork"}
      ${mkClass "parpa-decor-bee" "icon-${prefix}-decor-bee"}
      ${mkClass "parpa-decor-butterfly" "icon-${prefix}-decor-butterfly"}
      ${mkClass "parpa-app-cricket" "icon-app-cricket"}
      ${mkClass "parpa-app-cricket2" "icon-app-cricket2"}
      ${mkClass "parpa-app-cricket3" "icon-app-cricket3"}
      ${mkClass "parpa-app-linux" "icon-app-linux"}
      ${mkClass "parpa-app-linux2" "icon-app-linux2"}
      ${mkClass "parpa-app-linux3" "icon-app-linux3"}
      ${mkClass "parpa-app-gardening" "icon-app-gardening"}
      ${mkClass "parpa-app-gardening2" "icon-app-gardening2"}
      ${mkClass "parpa-app-gardening3" "icon-app-gardening3"}
      ${mkClass "parpa-app-gardening4" "icon-app-gardening4"}
      ${mkClass "parpa-app-gardening5" "icon-app-gardening5"}
      ${mkClass "parpa-app-gardening6" "icon-app-gardening6"}
    '';

  # ------------------------------------------------------------------
  # 8-bit / pixel structural helpers
  # ------------------------------------------------------------------
  pixelBaseFor = palette: hero: ''
    /* Page looks like a Game Boy / NES screen */
    .dark.theme-slate,
    .dark.theme-slate #__next,
    .dark.theme-slate input,
    .dark.theme-slate button,
    .dark.theme-slate select,
    .dark.theme-slate textarea {
      font-family: 'Press Start 2P', 'VT323', monospace !important;
      image-rendering: pixelated !important;
    }

    /* 8px grid background */
    .dark.theme-slate #background,
    .dark.theme-slate body {
      background:
        linear-gradient(rgba(${palette.border}, 0.12) 1px, transparent 1px),
        linear-gradient(90deg, rgba(${palette.border}, 0.12) 1px, transparent 1px),
        rgb(${palette.bg}) !important;
      background-size: 8px 8px, 8px 8px, 100% 100% !important;
    }

    /* Zero rounding everywhere */
    .dark.theme-slate .service-card,
    .dark.theme-slate .service-icon,
    .dark.theme-slate .bookmark,
    .dark.theme-slate .widget-container,
    .dark.theme-slate input,
    .dark.theme-slate button,
    .dark.theme-slate select {
      border-radius: 0 !important;
    }

    /* Inventory-slot service cards: thick pixel outline + shadow */
    .dark.theme-slate .service-card {
      background-color: rgb(${palette.surface}) !important;
      border: 3px solid rgb(${palette.border}) !important;
      box-shadow:
        inset -3px -3px 0 rgba(${palette.black}, 0.35),
        inset 3px 3px 0 rgba(${palette.white}, 0.06),
        4px 4px 0 rgba(${palette.black}, 0.45) !important;
      padding: 0.65rem 0.75rem !important;
      margin-bottom: 0.75rem !important;
      transition: transform 80ms ease, border-color 80ms ease !important;
    }
    .dark.theme-slate .service-card:hover {
      border-color: rgb(${palette.accent}) !important;
      transform: translate(-1px, -1px) !important;
      box-shadow:
        inset -3px -3px 0 rgba(${palette.black}, 0.35),
        inset 3px 3px 0 rgba(${palette.white}, 0.10),
        6px 6px 0 rgba(${palette.accent}, 0.35) !important;
    }

    /* Sunken icon slot with beveled pixel border */
    .dark.theme-slate .service-icon {
      width: 40px !important;
      height: 40px !important;
      min-width: 40px !important;
      margin-right: 0.8rem !important;
      background-color: rgb(${palette.surface2}) !important;
      border: 3px solid rgb(${palette.border}) !important;
      border-top-color: rgb(${palette.black}) !important;
      border-left-color: rgb(${palette.black}) !important;
      border-right-color: rgba(${palette.white}, 0.12) !important;
      border-bottom-color: rgba(${palette.white}, 0.12) !important;
      box-shadow: inset 0 0 0 2px rgba(${palette.black}, 0.35) !important;
    }

    /* Names are tiny pixel font; descriptions even tinier mono */
    .dark.theme-slate .service-name {
      color: rgb(${palette.text}) !important;
      font-size: 0.55rem !important;
      line-height: 1.4 !important;
    }
    .dark.theme-slate .service-description {
      color: rgb(${palette.muted}) !important;
      font-family: 'JetBrains Mono', ui-monospace, monospace !important;
      font-size: 0.5rem !important;
      line-height: 1.3 !important;
    }

    /* Group headers as box banners */
    .dark.theme-slate .service-group-name,
    .dark.theme-slate button.service-group-name {
      font-family: 'Press Start 2P', monospace !important;
      font-size: 0.62rem !important;
      line-height: 1.4 !important;
      font-weight: 400 !important;
      text-transform: uppercase !important;
      letter-spacing: 0.02em !important;
      display: flex !important;
      align-items: center !important;
      text-align: left !important;
      width: 100% !important;
      color: rgb(${palette.bg}) !important;
      background-color: rgb(${palette.gold}) !important;
      border: 3px solid rgb(${palette.border}) !important;
      box-shadow: 4px 4px 0 rgba(${palette.black}, 0.45) !important;
      padding: 0.55rem 0.5rem !important;
      margin: 1.1rem 0 0.75rem 0 !important;
    }

    /* Widgets as status panels */
    .dark.theme-slate .widget-container {
      font-family: 'JetBrains Mono', ui-monospace, monospace !important;
      background-color: rgb(${palette.surface}) !important;
      border: 3px solid rgb(${palette.border}) !important;
      box-shadow:
        inset -3px -3px 0 rgba(${palette.black}, 0.35),
        inset 3px 3px 0 rgba(${palette.white}, 0.06),
        4px 4px 0 rgba(${palette.black}, 0.45) !important;
      padding: 0.6rem !important;
      margin-bottom: 0.8rem !important;
    }
    .dark.theme-slate .widget-container .information-widget-resource {
      background: transparent !important;
      border: none !important;
      box-shadow: none !important;
    }
    .dark.theme-slate .widget-container svg,
    .dark.theme-slate .widget-container img {
      color: rgb(${palette.accent}) !important;
    }
    .dark.theme-slate .widget-container .resource-usage {
      background-color: rgba(${palette.border}, 0.5) !important;
      border: 2px solid rgb(${palette.border}) !important;
      border-radius: 0 !important;
    }
    .dark.theme-slate .widget-container .resource-usage > div {
      background-color: rgb(${palette.accent}) !important;
      border-radius: 0 !important;
    }
    .dark.theme-slate .widget-container .text-theme-500,
    .dark.theme-slate .widget-container [class*="text-theme-500"] {
      color: rgb(${palette.gold}) !important;
    }

    /* Command header / page title */
    .dark.theme-slate #__next h1,
    .dark.theme-slate #__next .title,
    .dark.theme-slate #__next header .title,
    .dark.theme-slate #__next header h1 {
      font-family: 'Press Start 2P', monospace !important;
      color: rgb(${palette.gold}) !important;
      line-height: 1.5 !important;
      font-size: 0.85rem !important;
      text-shadow: 3px 3px 0 rgba(${palette.black}, 0.5) !important;
    }

    /* Top command bar: logo + title */
    .dark.theme-slate #information-widgets::before {
      content: "HOME // DASHBOARD";
      display: flex;
      align-items: center;
      width: 100%;
      min-height: 52px;
      font-family: 'Press Start 2P', monospace !important;
      font-size: 0.58rem !important;
      font-weight: 400 !important;
      color: rgb(${palette.gold});
      letter-spacing: 0.04em;
      text-transform: uppercase;
      text-indent: 56px;
      line-height: 1.4;
      background-image: url(${hero});
      background-repeat: no-repeat;
      background-position: 0.75rem center;
      background-size: 40px 40px;
      image-rendering: pixelated;
      background-color: rgb(${palette.surface});
      border: 3px solid rgb(${palette.border});
      box-shadow:
        inset -3px -3px 0 rgba(${palette.black}, 0.35),
        inset 3px 3px 0 rgba(${palette.white}, 0.06),
        4px 4px 0 rgba(${palette.black}, 0.45) !important;
      margin-bottom: 0.9rem;
      padding: 0.35rem 0;
    }

    /* Status strip after widgets */
    .dark.theme-slate #information-widgets::after {
      content: "PLAYER 1 // PRIVATE NETWORK // OPS ONLINE";
      display: block;
      width: 100%;
      font-family: 'Press Start 2P', monospace !important;
      font-size: 0.45rem !important;
      font-weight: 400 !important;
      color: rgb(${palette.accent});
      letter-spacing: 0.08em;
      text-transform: uppercase;
      line-height: 1.5;
      background-color: rgb(${palette.surface2});
      border: 3px solid rgb(${palette.border});
      box-shadow: 4px 4px 0 rgba(${palette.black}, 0.45) !important;
      padding: 0.5rem;
      margin-top: 0.8rem;
    }

    /* Reduced motion */
    @media (prefers-reduced-motion: reduce) {
      .dark.theme-slate .service-card,
      .dark.theme-slate .service-icon,
      .dark.theme-slate .service-group-name,
      .dark.theme-slate .widget-container {
        transition: none !important;
      }
    }
  '';

  gameboyBaseFor = palette: hero: ''
    /* Game Boy / DMG-style palette variant */
    ${pixelBaseFor palette hero}

    .dark.theme-slate #background,
    .dark.theme-slate body {
      background: rgb(${palette.bg}) !important;
    }

    .dark.theme-slate .service-card {
      background-color: rgb(${palette.surface}) !important;
      border: 2px solid rgb(${palette.border}) !important;
      box-shadow: 4px 4px 0 rgba(${palette.black}, 0.35) !important;
    }
    .dark.theme-slate .service-card:hover {
      border-color: rgb(${palette.accent}) !important;
      box-shadow: 5px 5px 0 rgba(${palette.accent}, 0.35) !important;
    }

    .dark.theme-slate .service-group-name,
    .dark.theme-slate button.service-group-name {
      font-family: 'VT323', monospace !important;
      font-size: 1.05rem !important;
      line-height: 1.1 !important;
      color: rgb(${palette.bg}) !important;
      background-color: rgb(${palette.gold}) !important;
      border: 2px solid rgb(${palette.border}) !important;
      box-shadow: 4px 4px 0 rgba(${palette.black}, 0.35) !important;
    }

    .dark.theme-slate .service-name {
      font-size: 0.7rem !important;
    }
    .dark.theme-slate .service-description {
      font-size: 0.6rem !important;
    }

    .dark.theme-slate #__next h1,
    .dark.theme-slate #__next .title,
    .dark.theme-slate #__next header .title,
    .dark.theme-slate #__next header h1 {
      font-family: 'VT323', monospace !important;
      color: rgb(${palette.gold}) !important;
      line-height: 1.2 !important;
      font-size: 1.6rem !important;
      text-shadow: 2px 2px 0 rgba(${palette.black}, 0.5) !important;
    }

    .dark.theme-slate #information-widgets::before {
      font-family: 'VT323', monospace !important;
      font-size: 1rem !important;
      text-indent: 56px;
      background-image: url(${hero});
    }

    .dark.theme-slate #information-widgets::after {
      font-family: 'VT323', monospace !important;
      font-size: 0.85rem !important;
      letter-spacing: 0.1em;
    }
  '';

  catppuccinBaseFor = palette: hero: ''
    ${pixelBaseFor palette hero}

    /* Catppuccin upsizes the pixel art so it doesn't disappear */
    .dark.theme-slate .service-icon {
      width: 128px !important;
      height: 128px !important;
      min-width: 128px !important;
      margin-right: 1.5rem !important;
      background-color: rgb(${palette.elevated}) !important;
      border-color: rgb(${palette.border}) !important;
      box-shadow:
        inset 0 0 0 2px rgba(${palette.white}, 0.10),
        inset 0 0 0 4px rgba(${palette.black}, 0.35),
        3px 3px 0 rgba(${palette.black}, 0.45) !important;
    }
    .dark.theme-slate .service-icon img,
    .dark.theme-slate .service-icon svg {
      width: 100% !important;
      height: 100% !important;
      max-width: 100% !important;
      max-height: 100% !important;
      object-fit: contain !important;
      image-rendering: pixelated !important;
    }
    .dark.theme-slate .service-icon::before,
    .dark.theme-slate .services-group[data-pixel-group] .service-group-name::before,
    .dark.theme-slate .services-group[data-pixel-group] button.service-group-name::before {
      background-size: 96px 96px !important;
      filter:
        drop-shadow(1px 1px 0 rgba(0, 0, 0, 0.70))
        drop-shadow(0 0 3px rgba(${palette.gold}, 0.35)) !important;
    }
    .dark.theme-slate .services-group[data-pixel-group] .service-group-name::before,
    .dark.theme-slate .services-group[data-pixel-group] button.service-group-name::before {
      width: 80px !important;
      height: 80px !important;
      margin-right: 1.1rem !important;
    }
    .dark.theme-slate #information-widgets::before {
      min-height: 196px !important;
      background-size: 160px 160px !important;
      text-indent: 208px !important;
      font-size: 1.05rem !important;
      background-color: rgb(${palette.surface}) !important;
      border-color: rgb(${palette.border}) !important;
    }
    .dark.theme-slate .service-card {
      padding: 1.1rem 1.25rem !important;
    }
    .dark.theme-slate .service-name {
      font-size: 0.92rem !important;
    }
    .dark.theme-slate .service-description {
      font-size: 0.8rem !important;
    }

    .dark.theme-slate #information-widgets::after {
      content: "PIXEL GARDEN // OPS ONLINE";
    }
  '';

  # ------------------------------------------------------------------
  # Theme switcher CSS hooks
  # ------------------------------------------------------------------
  switcherFor = palette: ''
    /* Theme switcher bar stays inside the footer */
    #parpa-theme-switcher {
      color: rgb(${palette.gold}) !important;
      border-color: rgb(${palette.border}) !important;
      background-color: rgb(${palette.surface2}) !important;
      box-shadow: 4px 4px 0 rgba(${palette.black}, 0.45) !important;
    }
    #parpa-theme-switcher button[aria-pressed="true"] {
      background-color: rgb(${palette.accent}) !important;
      color: rgb(${palette.bg}) !important;
      border-color: rgb(${palette.accent}) !important;
    }
  '';
in
{
  # ------------------------------------------------------------------
  # Catppuccin — 8-bit palette swapped to mocha
  # ------------------------------------------------------------------
  catppuccin =
    googleFonts
    + colorsFor catppuccin
    + catppuccinBaseFor catppuccin (heroFor "catppuccin")
    + pixelIconsFor "catppuccin"
    + decorClassesFor "catppuccin";
}

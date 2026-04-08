# Migrate Neovim from nixCats to nix-wrapper-modules

> **Status: COMPLETE** — Migration finished on 2026-04-08. All phases done and verified building on workstation.

## Context

nixCats is being superseded by nix-wrapper-modules, created by the same author. nix-wrapper-modules offers:
- **Module system**: composable specs with `specMods` for custom fields, vs nixCats' flat category/package definitions
- **Simpler lua bridge**: `nixInfo(default, "path", "to", "value")` vs multiple nixCats APIs (`nixCats()`, `.extra()`, `.pawsible()`, `nixCatsUtils`)
- **Built-in PATH management**: `postpkgs`/`prepkgs` per spec vs manual `lspsAndRuntimeDeps` merging
- **Dynamic config switching**: `config.settings.config_directory` with lua inline expressions vs separate package variants
- **Wrapper variants**: compose multiple tools (e.g. opencode) alongside neovim
- **Future**: language modules ecosystem (`languages.nix.enable = true`) similar to nvf

The neovim config at `modules/aspects/neovim/` has been migrated from nixCats to nix-wrapper-modules. 33 specs, all lua files updated.

## Phase 1: Nix-side restructure

### 1a. Switch flake input
**File: `modules/aspects/neovim/default.nix`**
- Replace `flake-file.inputs.nixCats` with `flake-file.inputs.nix-wrapper-modules`
- Keep all `plugins-*` inputs (they'll be consumed by `pluginsFromPrefix` instead of `standardPluginOverlay`)
- Keep `oxy2dev-nvim-scripts` input
- Change `imports = [ inputs.nixCats.homeModule ]` to `imports = [ inputs.nix-wrapper-modules.homeModules.neovim ]`
- Replace `nixCats = { ... }` with `wrappers.neovim = { imports = [ (import ./nix inputs) ]; }`
- Keep XDG config file mappings and cachix settings in the homeManager block

### 1b. Create `nix/default.nix` — main wrapper config
**New file: `modules/aspects/neovim/nix/default.nix`**

Based on birdeevim pattern:
```nix
inputs: { config, wlib, lib, pkgs, ... }: {
  imports = [ wlib.wrapperModules.neovim ./nvim-lib.nix ./specs.nix ];
  config.package = pkgs.neovim-unwrapped;
  config.settings.config_directory = /* dynamic, see Phase 3 */;
  config.settings.aliases = [ "vi" ];
  config._module.args.inputs = inputs;
}
```

### 1c. Create `nix/nvim-lib.nix` — helpers and custom spec fields
**New file: `modules/aspects/neovim/nix/nvim-lib.nix`**

Copy birdeevim's pattern exactly:
- `options.settings.cats` — auto-generated `builtins.mapAttrs (_: v: v.enable) config.specs`
- `options.nvim-lib.pluginsFromPrefix` — scans inputs for `plugins-*` prefix, builds vim plugins
- `options.nvim-lib.neovimPlugins` — applies `pluginsFromPrefix "plugins-" inputs`
- `config.specMods` — adds `postpkgs`, `mainInfo`, `settings` fields to all specs
- `config.suffixVar` / `config.prefixVar` — collects postpkgs/prepkgs into PATH

### 1d. Create `nix/specs.nix` — all plugin and LSP declarations
**New file: `modules/aspects/neovim/nix/specs.nix`**

Maps current categories to specs. Each spec combines plugins + LSPs/tools from the same domain:

| Current nixCats category | New spec | Contains |
|---|---|---|
| `startupPlugins.general` | `specs.general` | lze, lzextras, vim-repeat, plenary, oil, SchemaStore, web-devicons, auto-session + general tools (ctags, rg, fd) |
| `startupPlugins.themer` | `specs.colorscheme` | catppuccin-nvim (dynamic lookup) |
| `optionalPlugins.debug` | `specs.debug` | nvim-dap, nvim-dap-view, nvim-dap-go, debugmaster, nvim-nio |
| `optionalPlugins.test` | `specs.test` | neotest, neotest-golang, nvim-coverage, vim-dotenv |
| `optionalPlugins.lint` | `specs.lint` | nvim-lint |
| `optionalPlugins.format` | `specs.format` | conform-nvim |
| `optionalPlugins.neonixdev` | `specs.neonixdev` | lazydev-nvim |
| `optionalPlugins.general.ai` | `specs.ai` | sidekick-nvim |
| `optionalPlugins.general.cmp` | `specs.cmp` | blink-cmp, blink-compat, luasnip, etc. |
| `optionalPlugins.general.treesitter` | `specs.treesitter` | nvim-treesitter.withAllGrammars |
| `optionalPlugins.general.telescope` | `specs.telescope` | telescope + extensions |
| `optionalPlugins.general.always` | `specs.lsp-core` | nvim-lspconfig |
| `optionalPlugins.general.git` | `specs.git` | gitsigns, neogit, diffview, etc. |
| `optionalPlugins.general.diagnostics` | `specs.diagnostics` | trouble-nvim |
| `optionalPlugins.general.editor` | `specs.editor` | mini, refactoring, arrow, snacks, flash, etc. |
| `optionalPlugins.general.extra` | `specs.extra` | fidget, comment, nvim-dbee |
| `optionalPlugins.general.notes` | `specs.notes` | markview, zk, img-clip |
| `optionalPlugins.general.ui` | `specs.ui` | indent-blankline, lualine, dropbar, etc. |
| `lspsAndRuntimeDeps.go` | `specs.go` | `data = null; postpkgs = [gopls delve ...]` |
| `lspsAndRuntimeDeps.nix` | `specs.nix` | `data = null; postpkgs = [nixd nixfmt ...]; mainInfo.nixdExtras = {...}` |
| (similar for all 16 languages) | `specs.<lang>` | `data = null; postpkgs = [...]` |

Info values (non-boolean data passed to lua):
```nix
config.info = {
  colorscheme = "catppuccin";
  lspDebugMode = false;
  colors = stylixColors;  # passed from homeManager context
};
```

## Phase 2: Lua migration

### 2a. Create `lua/nix_utils/init.lua` — replaces `lua/nixCatsUtils/`
Based on birdeevim's `lua/birdee/utils/init.lua` pattern:

```lua
local M = {}
local nixInfo = _G.nixInfo or function(default, ...) return default end

M.isNix = vim.g.nix_info_plugin_name ~= nil

function M.get_nix_plugin_path(name)
  if M.isNix then
    return nixInfo(nil, "plugins", "lazy", name) or nixInfo(nil, "plugins", "start", name)
  else
    return vim.api.nvim_get_runtime_file("pack/*/*/" .. name, false)[1]
  end
end

M.for_cat_handler = {
  spec_field = "for_cat",
  set_lazy = false,
  modify = function(plugin)
    if M.isNix then
      if type(plugin.for_cat) == "table" then
        plugin.enabled = nixInfo(plugin.for_cat.default, "settings", "cats", plugin.for_cat.cat)
      elseif type(plugin.for_cat) == "string" then
        plugin.enabled = nixInfo(false, "settings", "cats", plugin.for_cat)
      end
    end
    return plugin
  end,
}

return M
```

### 2b. Update `init.lua` (root entry point)
Replace nixCatsUtils bootstrap with nixInfo global setup:
```lua
do
  local ok
  ok, _G.nixInfo = pcall(require, vim.g.nix_info_plugin_name)
  if not ok then
    package.loaded[vim.g.nix_info_plugin_name or "nix-info"] = setmetatable({}, {
      __call = function(_, default) return default end,
    })
    _G.nixInfo = require(vim.g.nix_info_plugin_name or "nix-info")
  end
  nixInfo.isNix = vim.g.nix_info_plugin_name ~= nil
end
require("config")
```

### 2c. Update `lua/config/init.lua`
- Replace `require("nixCatsUtils.lzUtils").for_cat` → `require("nix_utils").for_cat_handler`
- Replace all `nixCats("category")` → `nixInfo(false, "settings", "cats", "category")`

### 2d. Systematic lua replacements across all files

| Old | New | Why |
|---|---|---|
| `nixCats("debug")` | `nixInfo(false, "settings", "cats", "debug")` | boolean spec check |
| `nixCats("test")` | `nixInfo(false, "settings", "cats", "test")` | boolean spec check |
| `nixCats("lint")` | `nixInfo(false, "settings", "cats", "lint")` | boolean spec check |
| `nixCats("format")` | `nixInfo(false, "settings", "cats", "format")` | boolean spec check |
| `nixCats("lspDebugMode")` | `nixInfo(false, "info", "lspDebugMode")` | non-boolean, moved to info |
| `nixCats("lua")` | `nixInfo(false, "settings", "cats", "lua")` | boolean spec check |
| `nixCats("neonixdev")` | `nixInfo(false, "settings", "cats", "neonixdev")` | boolean spec check |
| `nixCats("nix")` | `nixInfo(false, "settings", "cats", "nix")` | boolean spec check |
| `nixCats("general.telescope")` | `nixInfo(false, "settings", "cats", "telescope")` | flattened spec name |
| `nixCats("colors")` | `nixInfo(nil, "info", "colors")` | non-boolean, in info |
| `nixCats("colorscheme")` | `nixInfo(nil, "info", "colorscheme")` | non-boolean, in info |
| `nixCats.extra("nixdExtras.nixpkgs")` | `nixInfo(nil, "nixdExtras", "nixpkgs")` | mainInfo from nix spec |
| `nixCats.extra("nixdExtras.nixos_options")` | `nixInfo(nil, "nixdExtras", "nixos_options")` | mainInfo |
| `nixCats.extra("nixdExtras.home_manager_options")` | `nixInfo(nil, "nixdExtras", "home_manager_options")` | mainInfo |
| `nixCats.pawsible({"allPlugins","opt","X"})` | `nixInfo(nil, "plugins", "lazy", "X")` | plugin path lookup |
| `nixCats.pawsible({"allPlugins","start","X"})` | `nixInfo(nil, "plugins", "start", "X")` | plugin path lookup |
| `nixCats.nixCatsPath` | info plugin path (TBD from nix-wrapper-modules) | lazydev config |
| `require("nixCatsUtils").isNixCats` | `require("nix_utils").isNix` | nix detection |
| `for_cat = "general.X"` | `for_cat = "X"` | flattened spec names |

**Files requiring changes** (grep for `nixCats` across lua/):
- `init.lua`
- `lua/config/init.lua`
- `lua/config/LSPs/init.lua` (heaviest — pawsible, extra, nixCatsPath, category checks)
- `lua/config/LSPs/on_attach.lua`
- `lua/config/plugins/colorscheme.lua`
- `lua/config/plugins/snacks.lua`
- `lua/config/debug/init.lua`
- `lua/config/non_nix_download.lua`

## Phase 3: Handle wrapped vs unwrapped config (regularCats replacement)

Following birdeevim's `test_mode` pattern in `nix/default.nix`:

```nix
options.settings.unwrapped_mode = lib.mkOption { type = lib.types.bool; default = false; };
options.settings.wrapped_config = lib.mkOption { default = ./..; };
options.settings.unwrapped_config = lib.mkOption {
  default = lib.generators.mkLuaInline "vim.uv.os_homedir() .. '/nixicle/modules/aspects/neovim'";
};
config.settings.config_directory = if config.settings.unwrapped_mode
  then config.settings.unwrapped_config
  else config.settings.wrapped_config;
config.binName = lib.mkIf config.settings.unwrapped_mode (lib.mkDefault "nvim");
config.settings.aliases = lib.mkIf (config.binName != "nvim") [ "vi" ];
```

In the den aspect homeManager, install both variants:
```nix
wrappers.neovim = {
  imports = [ (import ./nix inputs) ];
  # Default: wrapRc=true equivalent (nixCats binary)
};
# TODO: figure out if wrapperVariants work at the homeModules level,
# or if we need a second wrappers.neovim-unwrapped entry
```

## Phase 4: Cleanup

Deleted:
- [x] `modules/aspects/neovim/_config.nix`
- [x] `modules/aspects/neovim/_plugins.nix`
- [x] `modules/aspects/neovim/_lsp-and-tools.nix`
- [x] `modules/aspects/neovim/_package-definitions.nix`
- [x] `modules/aspects/neovim/lua/nixCatsUtils/` (entire directory)

Created:
- [x] `modules/aspects/neovim/_nix/default.nix` (note: `_nix/` not `nix/` — import-tree excludes `/_` paths)
- [x] `modules/aspects/neovim/_nix/nvim-lib.nix`
- [x] `modules/aspects/neovim/_nix/specs.nix`
- [x] `modules/aspects/neovim/lua/nix_utils/init.lua`

## Verification

- [x] `nix build .#homeConfigurations."haseeb@workstation".activationPackage` — builds
- [x] `nh home switch` — activates successfully
- [x] 33 specs verified via `nix eval`
- [x] Neovim launches without errors (catppuccin spec changed from `lazy = true` to start)
- [ ] Full `:checkhealth` audit

## Implementation Notes

### import-tree exclusion
The wrapper config directory must be named with a `_` prefix (`_nix/`) so import-tree skips it. import-tree uses `andNot (lib.hasInfix "/_")` — any path containing `/_` is excluded from auto-import. Files meant to be used as curried functions (not modules) must live under `_`-prefixed directories.

### Stylix colors passthrough
`config.lib.stylix.colors.withHashtag` contains function values that break `generators.toLua`. Fixed with:
```nix
_module.args.stylixColors =
  let raw = config.lib.stylix.colors.withHashtag or {};
  in lib.filterAttrs (_: v: builtins.isString v) raw;
```

### colorscheme spec must not be lazy
`catppuccin-nvim` is `require()`d directly in `colorscheme.lua` at startup. Setting `lazy = true` puts it in `opt/` — not on rtp at init time. The spec must omit `lazy` (defaults to start).

### Standalone homeConfigurations
`homeConfigurations."haseeb@workstation"` is exposed for `nh home switch` without a full NixOS build. The niri homeModule and `nix.package` are injected only in the standalone instantiate function in `modules/hosts.nix` — NOT in the workstation provides block — to avoid conflicts with the NixOS niri nixosModule.

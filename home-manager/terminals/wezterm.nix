{ config, lib, ... }:

with lib;
let
  cfg = config.modules.terminals.wezterm;
in
{
  options.modules.terminals.wezterm = {
    enable = mkEnableOption "enable wezterm terminal emulator";
  };

  config = mkIf cfg.enable {
    programs.wezterm = {
      enable = true;
      colorSchemes = { };
      extraConfig =
        # lua
        ''
          local wezterm = require 'wezterm'
          local act = wezterm.action
          return {
          	color_scheme = "Catppuccin Mocha",
          	font = wezterm.font "${config.fontProfiles.monospace.family}",
          	font_size = 14.0,
          	enable_tab_bar = false,
          	leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 },
          	keys = {
          		-- Send C-a when pressing C-a twice
          		{ key = "a",          mods = "LEADER|CTRL", action = act.SendKey { key = "a", mods = "CTRL" } },
          		{ key = "c",          mods = "LEADER",      action = act.ActivateCopyMode },
          		{ key = "phys:Space", mods = "LEADER",      action = act.ActivateCommandPalette },

          		-- Pane keybindings
          		{ key = "s",          mods = "LEADER",      action = act.SplitVertical { domain = "CurrentPaneDomain" } },
          		{ key = "v",          mods = "LEADER",      action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
          		{ key = "h",          mods = "LEADER",      action = act.ActivatePaneDirection("Left") },
          		{ key = "j",          mods = "LEADER",      action = act.ActivatePaneDirection("Down") },
          		{ key = "k",          mods = "LEADER",      action = act.ActivatePaneDirection("Up") },
          		{ key = "l",          mods = "LEADER",      action = act.ActivatePaneDirection("Right") },
          		{ key = "q",          mods = "LEADER",      action = act.CloseCurrentPane { confirm = true } },
          		{ key = "z",          mods = "LEADER",      action = act.TogglePaneZoomState },
          		{ key = "o",          mods = "LEADER",      action = act.RotatePanes "Clockwise" },
          		-- We can make separate keybindings for resizing panes
          		-- But Wezterm offers custom "mode" in the name of "KeyTable"
          		{ key = "r",          mods = "LEADER",      action = act.ActivateKeyTable { name = "resize_pane", one_shot = false } },

          		-- Tab keybindings
          		{ key = "t",          mods = "LEADER",      action = act.SpawnTab("CurrentPaneDomain") },
          		{ key = "[",          mods = "LEADER",      action = act.ActivateTabRelative(-1) },
          		{ key = "]",          mods = "LEADER",      action = act.ActivateTabRelative(1) },
          		{ key = "n",          mods = "LEADER",      action = act.ShowTabNavigator },
          		{
          			key = "e",
          			mods = "LEADER",
          			action = act.PromptInputLine {
          				description = wezterm.format {
          					{ Attribute = { Intensity = "Bold" } },
          					{ Foreground = { AnsiColor = "Fuchsia" } },
          					{ Text = "Renaming Tab Title...:" },
          				},
          				action = wezterm.action_callback(function(window, pane, line)
          					if line then
          						window:active_tab():set_title(line)
          					end
          				end)
          			},
          		},
          	},
          }
        '';
    };
  };
}

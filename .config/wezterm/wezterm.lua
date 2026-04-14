local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'Regular' })
config.font_size = 14
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' } -- enable ligatures

-- Appearance
config.color_scheme = 'Tokyo Night'
config.window_background_opacity = 1.0
config.enable_tab_bar = false -- using tmux for multiplexing

-- Window padding
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

-- Shell
config.default_prog = { '/usr/bin/zsh' }

-- Misc
config.audible_bell = 'Disabled'
config.scrollback_lines = 10000

return config

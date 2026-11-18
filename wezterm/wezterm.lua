-- WezTerm (sustituto de kitty)
-- Archivo real: C:\Users\ricar\Win2Hyprland\wezterm\wezterm.lua
-- (~\.config\wezterm es un junction a Win2Hyprland\wezterm)
-- WezTerm recarga este archivo automáticamente al guardarlo.
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Shell por defecto: PowerShell
config.default_prog = { 'powershell.exe', '-NoLogo' }

-- Aspecto
config.color_scheme = 'Tokyo Night'
config.font = wezterm.font('JetBrains Mono')
config.font_size = 11.0
config.window_background_opacity = 0.95
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }

-- Sin barra de título (GlazeWM gestiona la ventana), como kitty en Hyprland
config.window_decorations = 'RESIZE'
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- Sin campana ni confirmación al cerrar
config.audible_bell = 'Disabled'
config.window_close_confirmation = 'NeverPrompt'

return config

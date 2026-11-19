-- WezTerm: traducción de mi kitty.conf de Hyprland
-- Archivo real: C:\Users\ricar\Win2Hyprland\wezterm\wezterm.lua
-- (~\.config\wezterm es un junction a Win2Hyprland\wezterm)
-- WezTerm recarga este archivo automáticamente al guardarlo.
local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- ---------- Shells ----------
-- Fuera de WSL: PowerShell 7 (pwsh). PowerShell 5.1 se rompía más al redimensionar.
config.default_prog = { 'pwsh.exe', '-NoLogo' }

-- Linux: si existe la distro de WSL "archlinux", WezTerm abre directamente su shell
-- (zsh + Oh My Zsh) empezando en tu carpeta de usuario de Windows (/mnt/c/Users/ricar). Si no existe, se queda en pwsh.
local WSL_DISTRO = 'WSL:archlinux'
local wsl_domains = wezterm.default_wsl_domains()
for _, dom in ipairs(wsl_domains) do
  -- Empezar en C:\Users\ricar (visto desde Linux), como una terminal de Windows
  dom.default_cwd = '/mnt/c/Users/ricar'
  if dom.name == WSL_DISTRO then
    config.default_domain = WSL_DISTRO
  end
end
config.wsl_domains = wsl_domains

-- Menú para elegir shell: Ctrl+Shift+L
config.launch_menu = {
  { label = 'PowerShell 7', args = { 'pwsh.exe', '-NoLogo' }, domain = { DomainName = 'local' } },
  { label = 'Windows PowerShell 5.1', args = { 'powershell.exe', '-NoLogo' }, domain = { DomainName = 'local' } },
  { label = 'cmd', args = { 'cmd.exe' }, domain = { DomainName = 'local' } },
}

-- ---------- Fuentes ----------
-- font_family JetBrains Mono Nerd Font / font_size 16
-- (en Windows la Nerd Font se registra como "JetBrainsMono NF")
config.font = wezterm.font_with_fallback {
  'JetBrainsMono Nerd Font',
  'JetBrainsMono NF',
  'JetBrains Mono',
}
config.font_size = 16.0
-- disable_ligatures never → ligaduras activadas (por defecto en WezTerm)
-- modify_font underline_position -2 / underline_thickness 150%
config.underline_position = '-2px'
config.underline_thickness = '150%'

-- ---------- Colores ----------
config.colors = {
  foreground = '#e0e0e0',
  background = '#000000',

  cursor_bg = '#ffffff',
  cursor_fg = '#000000',
  cursor_border = '#ffffff',

  selection_fg = '#000000',
  selection_bg = '#b3d7ff',

  -- color0..color7
  ansi = {
    '#2e2e2e', '#ff3333', '#00ff00', '#ffff00',
    '#0f63eb', '#e015aa', '#00ffff', '#d0d0d0',
  },
  -- color8..color15
  brights = {
    '#666666', '#ff6666', '#33ff33', '#ffff33',
    '#3399ff', '#ff33ff', '#33ffff', '#ffffff',
  },

  -- tab_bar_background #000000 (pestañas con los colores por defecto de kitty)
  tab_bar = {
    background = '#000000',
    active_tab = { bg_color = '#eeeeee', fg_color = '#000000', intensity = 'Bold' },
    inactive_tab = { bg_color = '#999999', fg_color = '#444444' },
    inactive_tab_hover = { bg_color = '#bbbbbb', fg_color = '#222222' },
    new_tab = { bg_color = '#000000', fg_color = '#666666' },
    new_tab_hover = { bg_color = '#333333', fg_color = '#e0e0e0' },
  },
}

-- ---------- Fondo ----------
-- Negro sólido, sin transparencia (en kitty tenía background_opacity 0.86)
config.window_background_opacity = 1.0

-- ---------- Ventana ----------
config.window_padding = { left = 5, right = 5, top = 5, bottom = 5 } -- window_padding_width 5
config.window_decorations = 'RESIZE' -- hide_window_decorations titlebar-only
config.window_close_confirmation = 'NeverPrompt' -- confirm_os_window_close 0

-- ---------- Pestañas: arriba, estilo powerline ----------
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false -- tab_bar_edge top
config.hide_tab_bar_if_only_one_tab = true -- como kitty (tab_bar_min_tabs 2)
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32

local SEP = wezterm.nerdfonts.pl_left_hard_divider --
wezterm.on('format-tab-title', function(tab, tabs, _, cfg, hover)
  local c = cfg.colors.tab_bar
  local style = tab.is_active and c.active_tab or (hover and c.inactive_tab_hover or c.inactive_tab)
  -- color del separador: fondo de la siguiente pestaña (o de la barra si es la última)
  local next_bg = c.background
  local nxt = tabs[tab.tab_index + 2]
  if nxt then
    next_bg = nxt.is_active and c.active_tab.bg_color or c.inactive_tab.bg_color
  end
  local title = tab.tab_title ~= '' and tab.tab_title or tab.active_pane.title
  title = wezterm.truncate_right(title, cfg.tab_max_width - 4)
  return {
    { Background = { Color = style.bg_color } },
    { Foreground = { Color = style.fg_color } },
    { Text = ' ' .. (tab.tab_index + 1) .. ' ' .. title .. ' ' },
    { Background = { Color = next_bg } },
    { Foreground = { Color = style.bg_color } },
    { Text = SEP },
  }
end)

-- ---------- Scroll ----------
config.scrollback_lines = 5000

-- ---------- Campana ----------
config.audible_bell = 'Disabled' -- enable_audio_bell no

-- ---------- Cursor y ratón ----------
config.default_cursor_style = 'SteadyBlock' -- cursor_shape block
config.hide_mouse_cursor_when_typing = true -- mouse_hide_wait

-- ---------- Rendimiento ----------
-- repaint_delay 10 (~100 fps) / sync_to_monitor yes
config.max_fps = 120
config.front_end = 'WebGpu'
config.webgpu_power_preference = 'HighPerformance'

-- ---------- Atajos (los mismos que en kitty) ----------
-- En kitty "vsplit" = una al lado de otra  → SplitHorizontal en WezTerm
--          "hsplit" = una encima de otra   → SplitVertical en WezTerm
config.keys = {
  -- Divisiones
  { key = 'o', mods = 'CTRL|ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 't', mods = 'CTRL|ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'y', mods = 'CTRL|ALT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Navegar entre divisiones
  { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Down' },

  -- Redimensionar divisiones
  { key = 'LeftArrow', mods = 'CTRL|SHIFT|ALT', action = act.AdjustPaneSize { 'Left', 3 } },
  { key = 'RightArrow', mods = 'CTRL|SHIFT|ALT', action = act.AdjustPaneSize { 'Right', 3 } },
  { key = 'UpArrow', mods = 'CTRL|SHIFT|ALT', action = act.AdjustPaneSize { 'Up', 3 } },
  { key = 'DownArrow', mods = 'CTRL|SHIFT|ALT', action = act.AdjustPaneSize { 'Down', 3 } },

  -- Cerrar la división activa
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = false } },

  -- Nueva pestaña (ojo: AutoHotkey usa Ctrl+Alt+N para "siguiente canción", igual que Hyprland)
  { key = 'n', mods = 'CTRL|ALT', action = act.SpawnTab 'CurrentPaneDomain' },

  -- Elegir shell / distro (Arch, PowerShell, cmd) en una pestaña nueva
  { key = 'l', mods = 'CTRL|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|LAUNCH_MENU_ITEMS|DOMAINS' } },

  -- Navegar entre pestañas
  { key = 'PageUp', mods = 'CTRL', action = act.ActivateTabRelative(-1) },
  { key = 'PageDown', mods = 'CTRL', action = act.ActivateTabRelative(1) },
}

return config

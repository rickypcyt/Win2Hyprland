# Win2Hyprland

**My Hyprland config, literally, ported to Windows 11.**

I used Linux with Hyprland and switched to Windows. But I didn't want to lose my workflow: automatic window tiling, workspaces on `Alt+number`, everything from the keyboard, and a top bar just like my Waybar. This repo is exactly that: I took my `hyprland.conf` and my Waybar and translated them, shortcut by shortcut, to tools that run on Windows.

It's fast and works well day to day. I can indulge my habit of hammering `Alt+1234 4321` at full speed without anything breaking (I explain how below).

`hyprland-reference.conf` is my original Hyprland config, for comparison.

---

## What it uses (and its Linux equivalent)

| On Hyprland | On Windows | File |
|---|---|---|
| Hyprland (tiling, workspaces, shortcuts) | [GlazeWM](https://github.com/glzr-io/glazewm) | `glzr/glazewm/config.yaml` |
| Waybar | [Zebar](https://github.com/glzr-io/zebar) with a custom pack | `glzr/zebar/waybar/` |
| `playerctl`, `swayosd`, `grim`/`slurp`… | [AutoHotkey v2](https://www.autohotkey.com/) | `ahk/hotkeys.ahk` |
| kitty | [WezTerm](https://wezfurlong.org/wezterm/) | `wezterm/wezterm.lua` |
| Neovim | Neovim (same config, plugins pinned by `lazy-lock.json`) | `nvim/` |
| rofi | [Flow Launcher](https://www.flowlauncher.com/) | — (its own config) |

## What it looks like

- **Automatic tiling** with `gaps_in = 5` and `gaps_out = 10`, same as in Hyprland.
- **Dwindle-style layout**, like Hyprland's `layout = dwindle`. Each new window splits the focused one along its long side. With three windows, the first one takes the whole left half and the other two stack on the right. GlazeWM doesn't do this natively; a small helper (`ahk/glaze-bridge.ps1`) sets the split direction every time a window gets focus.
- **Rounded corners**, no borders or title bars.
- **No transparency**: all windows are opaque (in Hyprland I had `inactive_opacity = 0.9`; I dropped it here).
- **Focus follows the mouse**, like `follow_mouse = 1`.
- **Workspaces pinned per monitor:** 1 on the external monitor and 2 to 5 on the laptop screen, as I had with `workspace = N, monitor:…`.
- **35 px black top bar**, with JetBrainsMono Nerd Font and Catppuccin Mocha colors, just like my Waybar.

---

## Shortcuts

The logic is the same as in Hyprland:

- **`Win`** (`$mainMod`): open apps and manage windows.
- **`Alt`** (`$altMod`): workspaces.
- **`Ctrl+Alt`**: media, brightness and utilities.
- **`Ctrl+Alt+Shift`**: control of the window manager itself.

### Applications

| Shortcut | Opens | On Hyprland it was |
|---|---|---|
| `Win+Enter` | WezTerm | kitty |
| `Win+Space` | Flow Launcher (also `Alt+Space`) | rofi -show drun |
| `Win+E` | File Explorer | thunar |
| `Win+F` | Brave | brave |
| `Win+C` | WezTerm with Neovim | kitty nvim |
| `Win+O` | Obsidian | obsidian |
| `Win+S` | Spotify | spotify |
| `Win+Z` | WhatsApp | zapzap |
| `Win+Shift+D` | Discord | discord |
| `Win+N` | Wi-Fi settings | nmtui |
| `Win+B` | Bluetooth settings | blueman-manager |
| `Win+V` | Volume mixer | pavucontrol |
| `Win+T` | Touchpad settings | toggle-touchpad.sh |
| `Win+Q` | Lock the session | hyprlock |

### Windows

| Shortcut | Action |
|---|---|
| `Alt+W` | Close the window |
| `Win+I` | Toggle floating / tiling |
| `Win+Shift+F` | Fullscreen |
| `Win+←↑→↓` | Move the window in that direction |
| `Win+Shift+←↑→↓` | Move the window in that direction |
| `Win+M` | Change the tiling direction (horizontal / vertical) for the next window (dwindle takes over again on the next focus change) |

### Workspaces

| Shortcut | Action |
|---|---|
| `Alt+1` … `Alt+9`, `Alt+0` | Go to workspace 1…10 |
| `Alt+Shift+1` … `Alt+Shift+0` | Move the window to that workspace and follow it |

### Monitors

| Shortcut | Action | On Hyprland it was |
|---|---|---|
| `Win+Ctrl+L` | External monitor only | `Win+L` (extonly) |
| `Win+Shift+L` | Extend to both monitors | `Win+Shift+L` (bothmons) |
| `Ctrl+Alt+M` | Windows display switcher | monitors.sh |

`Win+L` can't be used because Windows reserves it for locking the session.

### Media, brightness and screenshots (AutoHotkey)

| Shortcut | Action |
|---|---|
| `Ctrl+Alt+P` | Play / pause |
| `Ctrl+Alt+N` | Next track |
| `Ctrl+Alt+]` or `Ctrl+Alt+'` | Brightness up 5 % |
| `Ctrl+Alt+[` or `Ctrl+Alt+;` | Brightness down 5 % |
| `Ctrl+Alt+U` | Screenshot of a region to the clipboard (formerly grim + slurp) |
| `Ctrl+Alt+0` | Night light settings |

The keyboard's media and brightness keys work as usual.

### GlazeWM

| Shortcut | Action |
|---|---|
| `Ctrl+Alt+Shift+R` | Reload the config |
| `Ctrl+Alt+Shift+E` | Quit GlazeWM |
| `Ctrl+Alt+Shift+Space` | Pause / resume tiling |

### Terminal (WezTerm, my kitty.conf translated)

Same style as my kitty:
- JetBrainsMono Nerd Font at 16.
- Solid black background (no transparency) and my 16-color palette.
- Block cursor and padding of 5.
- Tabs on top in powerline style (only shown with two or more).

**Linux commands:** WezTerm opens **zsh + Oh My Zsh inside WSL2 (Arch Linux)** by default, so it feels like the terminal I had on Linux. If the `archlinux` distro isn't installed, it falls back to PowerShell 7. Windows-only things (Neovim with `Win+C`, `:GCC`) are launched in the local Windows domain.

The prompt is **Powerlevel10k** on top of Oh My Zsh. `~/.zshrc` is a symlink to `zsh/zshrc` in this repo, and the prompt style is saved to `zsh/p10k.zsh`. Run `p10k configure` to change it.

I use the WezTerm **nightly** build (`winget install wez.wezterm.nightly`). The 2024 stable build ships an old ConPTY that garbles the text when the window is resized, which happens all the time with a tiling WM.

| Shortcut | Action |
|---|---|
| `Ctrl+Shift+L` | Pick a shell for a new tab: Arch (zsh), PowerShell 7, PowerShell 5.1, cmd |
| `Ctrl+Alt+T` / `Ctrl+Alt+O` | Split: new terminal to the side |
| `Ctrl+Alt+Y` | Split: new terminal below |
| `Ctrl+Shift+←↑→↓` | Move between splits |
| `Ctrl+Shift+Alt+←↑→↓` | Resize the split |
| `Ctrl+Shift+W` | Close the active split |
| `Ctrl+Alt+N` | New tab (intercepted by AutoHotkey's "next track", same as on Hyprland) |
| `Ctrl+Shift+T` | New tab (WezTerm shortcut that does work) |
| `Ctrl+PageUp` / `Ctrl+PageDown` | Previous / next tab |

### Neovim (my Linux config)

Same config as on Linux, with the plugins pinned to the same versions through `lazy-lock.json`. It includes Cyberdream, Telescope, nvim-tree, Treesitter, lualine, bufferline, harpoon, hop, LSP and formatting on save. The only changes for Windows:

- lazy.nvim installs itself on first launch.
- `:Kitty` / `:Term` open WezTerm in the current file's folder.
- `:GCC` compiles the current `.c` with MSYS2 gcc and runs it in a WezTerm window.
- `telescope-project` looks in `C:/coding` instead of `~/coding`.
- `hop.nvim` points to the maintained fork `smoka7/hop.nvim`, because the original repo was deleted.

The **same config is used inside WSL Arch**: `~/.config/nvim` is a symlink to this folder, so editing it once changes both. Arch has its own Neovim, plugins and language servers (installed with `pacman`), and the config detects the OS: on Arch, `:Kitty`/`:GCC` open WezTerm in the Arch domain and Telescope projects look in `/mnt/c/coding`. The clipboard is shared with Windows through `win32yank`.

The main shortcuts (leader = `Space`) are the same as on Linux:

- `Ctrl+F`: find files.
- `Space ff` / `fg` / `fb` / `fe` / `fp`: Telescope files, grep, buffers, browser here and browser in the parent folder.
- `Space e`: nvim-tree.
- `Ctrl+S`: save and format.
- `gd` / `K` / `gi`: LSP go to definition, hover and implementation.

---

## The bar (Zebar, Waybar style)

It has the same modules as my Waybar:

- **Left:**
  - Workspaces 1 to 5, always visible. The active one is shown in blue and you can click to switch.
  - System tray.
  - Spotify: click to pause or resume, middle-click for next, right-click for previous. Shown in italics when paused.
- **Center:** time `|` date `|` Ecuador time.
- **Right:**
  - CPU and RAM.
  - Volume: the scroll wheel raises or lowers it, right-click mutes, and left-click opens the mixer.
  - Battery, colored by charge level: green, blue, peach or red.

The bar is docked at the top and Windows reserves its space, so windows never slide underneath it.

Compared to my Waybar it lacks CPU temperature and brightness, because Zebar has no source for that data.

---

## Why it doesn't break when typing fast

On Hyprland I could hammer `Alt+1234 4321` and nothing happened, because the compositor itself manages workspaces. On Windows, GlazeWM has to hide and show every window manually. If keys arrived faster than it could keep up, keystrokes got lost, focus stayed on a hidden window, and the bar got out of sync.

I fixed it with two changes:

1. **`Alt+number` is handled by AutoHotkey, not GlazeWM.** AutoHotkey writes the number to a named pipe. A helper process (`ahk/glaze-bridge.ps1`) keeps a WebSocket open to GlazeWM and sends the switch right away, in about 46 ms instead of the ~270 ms it took to launch `glazewm.exe` for every key. If GlazeWM is busy, only the last key pressed is sent and the intermediate ones are discarded, so nothing piles up. When you stop pressing, it re-sends the last workspace once or twice, because GlazeWM sometimes jumps back to an earlier workspace after a burst.
2. **The bar talks directly to GlazeWM** over its WebSocket (`127.0.0.1:6123`), bypassing Zebar's module, which used to freeze. It re-queries the state on every event, checks every 500 ms in case one is missed, and reconnects on its own if GlazeWM restarts.

The bar stays in sync with GlazeWM in simulated bursts of up to 49 keystrokes in under 300 ms. The re-send step that guarantees landing on the last pressed workspace is newer and still being tested.

---

## Installation

```powershell
winget install glzr-io.glazewm
winget install glzr-io.zebar
winget install AutoHotkey.AutoHotkey
winget install wez.wezterm.nightly
winget install Flow-Launcher.Flow-Launcher
winget install Neovim.Neovim
winget install DEVCOM.JetBrainsMonoNerdFont
```

Clone the repo into `C:\Users\<your user>\Win2Hyprland` and link the config folders with junctions (no admin rights needed):

```powershell
New-Item -ItemType Junction -Path "$env:USERPROFILE\.glzr" -Target "$env:USERPROFILE\Win2Hyprland\glzr"
New-Item -ItemType Junction -Path "$env:USERPROFILE\.config\wezterm" -Target "$env:USERPROFILE\Win2Hyprland\wezterm"
New-Item -ItemType Junction -Path "$env:LOCALAPPDATA\nvim" -Target "$env:USERPROFILE\Win2Hyprland\nvim"
```

For Neovim, also install the tools its plugins use. Then open `nvim` once, or run `nvim --headless "+Lazy! restore" +qa`, so lazy.nvim downloads the plugins:

```powershell
winget install BurntSushi.ripgrep.MSVC
winget install sharkdp.fd
winget install JohnnyMorganz.StyLua
winget install LuaLS.lua-language-server
npm install -g pyright vscode-langservers-extracted prettier
```

clangd and gcc come from [MSYS2](https://www.msys2.org/) (UCRT64): `pacman -S mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-clang-tools-extra`.

Then open GlazeWM. It launches Zebar and the AutoHotkey shortcuts.

Some paths in `glzr/glazewm/config.yaml` contain my username (`C:/Users/ricar/...`): the AutoHotkey script, Brave, Obsidian, Discord and Flow Launcher. Replace them with yours. The monitor indices in `bind_to_monitor` depend on your display setup; you can see them with `glazewm query monitors`.

## Structure

```
Win2Hyprland/
├── glzr/
│   ├── glazewm/config.yaml   ← tiling, gaps, workspaces, shortcuts
│   └── zebar/
│       ├── settings.json     ← which bar starts
│       └── waybar/           ← the bar: bar.html, styles.css, zpack.json
├── ahk/hotkeys.ahk           ← Alt+number, media, brightness, screenshots
├── ahk/glaze-bridge.ps1      ← fast workspace switching + dwindle autotiling
├── wezterm/wezterm.lua       ← terminal
├── nvim/                     ← Neovim (init.lua, lua/, lazy-lock.json)
├── zsh/                      ← zshrc + Powerlevel10k style (WSL Arch)
├── hyprland-reference.conf   ← my original Hyprland config
└── CLAUDE.md                 ← notes for editing the config with Claude Code
```

## What can't be matched

- **Blur:** Windows doesn't allow it.
- **`Win+L`:** reserved by Windows.
- **No equivalent yet:** hiding the bar (`Win+P`), power menu (`Win+Escape`), switching audio output (`Ctrl+Alt+V`) and power profile (`Ctrl+Alt+B`).

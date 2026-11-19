<div align="center">

# 🪟 ➜ 🐧 Win2Hyprland

**My Hyprland setup, literally, ported to Windows 11.**

Tiling windows · dwindle layout · `Alt+number` workspaces · a Waybar-style bar · a kitty-like terminal · zsh on Arch · my Neovim config — all driven from the keyboard, just like on Linux.

`GlazeWM` · `Zebar` · `AutoHotkey v2` · `Alacritty` · `WSL Arch + zsh` · `Neovim` · `PowerShell 7` · `WezTerm`

</div>

---

I used Linux with Hyprland and moved to Windows, but I didn't want to lose the way I work. So I took my `hyprland.conf`, my Waybar, my kitty and my Neovim config and translated them, **shortcut by shortcut**, to tools that run on Windows. Where Windows or the tools couldn't do something, I wrote the missing piece myself (fast workspace switching, a dwindle autotiler, a Hyprland-style window swap, a recovery tool for lost windows…).

It's fast and it holds up day to day. I can hammer `Alt+1234 4321` at full speed and nothing breaks.

> `hyprland-reference.conf` is my original Hyprland config, kept for comparison.

## 📑 Contents

- [The stack](#-the-stack)
- [What it looks like](#-what-it-looks-like)
- [Shortcuts](#%EF%B8%8F-shortcuts)
- [Window layout: dwindle and swapping like Hyprland](#-window-layout-dwindle-and-swapping-like-hyprland)
- [The bar](#-the-bar-zebar-waybar-style)
- [Terminal: Alacritty + zsh on Arch](#-terminal-alacritty--zsh-on-arch)
- [Neovim](#-neovim)
- [PowerShell 7](#-powershell-7)
- [WezTerm (alternative terminal)](#-wezterm-alternative-terminal)
- [Under the hood](#-under-the-hood)
- [Installation](#-installation)
- [Repository layout](#-repository-layout)
- [Known limitations](#-known-limitations)

---

## 🧱 The stack

| On Hyprland / Linux | On Windows | Config |
|---|---|---|
| Hyprland (tiling, workspaces, binds) | [GlazeWM](https://github.com/glzr-io/glazewm) | `glzr/glazewm/config.yaml` |
| Hyprland's dwindle layout & `swapwindow` | A small helper of mine (C# in PowerShell) | `ahk/glaze-bridge.ps1` |
| Waybar | [Zebar](https://github.com/glzr-io/zebar) with my own widget pack | `glzr/zebar/waybar/` |
| `playerctl`, `swayosd`, `grim`/`slurp`, extra binds | [AutoHotkey v2](https://www.autohotkey.com/) | `ahk/hotkeys.ahk` |
| kitty | [Alacritty](https://alacritty.org/) | `alacritty/alacritty.toml` |
| zsh on Arch | **zsh inside WSL2 Arch Linux** | `zsh/zshrc` |
| Neovim | Neovim (same config on Windows *and* in Arch) | `nvim/` |
| rofi | [Flow Launcher](https://www.flowlauncher.com/) | its own settings |
| — | PowerShell 7 with an Arch-like `ls` | `powershell/profile.ps1` |
| kitty tabs/splits | [WezTerm](https://wezfurlong.org/wezterm/) (optional) | `wezterm/wezterm.lua` |

---

## 🎨 What it looks like

- **Automatic tiling** with `gaps_in = 5` and `gaps_out = 10`, exactly as in Hyprland.
- **Dwindle layout**: each new window splits the focused one along its long side, so three windows become *one big window on the left, two stacked on the right*.
- **Rounded corners**, no borders, no title bars, **no transparency** (every window is opaque).
- **Focus follows the mouse** (`follow_mouse = 1`).
- **Floating windows always stay on top** of tiled ones; dialogs and installers open floating and centered.
- **Workspaces pinned per monitor**: 1 on the external monitor, 2–5 on the laptop screen.
- **A 35 px black top bar** with JetBrainsMono Nerd Font and Catppuccin Mocha colors, a copy of my Waybar.
- **Terminal**: solid black, white **SemiBold** JetBrainsMono Nerd Font 16, my kitty 16-color palette, block cursor.

---

## ⌨️ Shortcuts

Same logic as my Hyprland config:

| Modifier | Used for |
|---|---|
| **`Win`** (`$mainMod`) | apps and windows |
| **`Alt`** (`$altMod`) | workspaces |
| **`Ctrl+Alt`** | media, brightness, screenshots, utilities |
| **`Ctrl+Alt+Shift`** | the window manager itself |

### 🚀 Apps

| Shortcut | Opens | On Hyprland |
|---|---|---|
| `Win+Enter` / `Alt+Enter` | Alacritty (zsh on Arch) | kitty |
| `Win+Space` (also `Alt+Space`) | Flow Launcher | rofi -show drun |
| `Win+C` | Neovim in Alacritty | kitty nvim |
| `Win+E` | File Explorer | thunar |
| `Win+F` | Brave | brave |
| `Win+O` | Obsidian | obsidian |
| `Win+S` | Spotify | spotify |
| `Win+Z` | WhatsApp | zapzap |
| `Win+Shift+D` | Discord | discord |
| `Win+N` | Wi-Fi settings | nmtui |
| `Win+B` | Bluetooth settings | blueman-manager |
| `Win+V` | Volume mixer | pavucontrol |
| `Win+T` | Touchpad settings | toggle-touchpad.sh |
| `Win+Q` | Lock the session | hyprlock |

### 🪟 Windows

| Shortcut | Action |
|---|---|
| `Alt+W` | Close the window |
| `Win+I` | Toggle floating / tiling (floating = centered and always on top) |
| `Win+Shift+F` | Fullscreen |
| `Win+←` / `Win+→` | Move the window to the next column, **splitting the window there** (bspwm/Hyprland style). Swaps with a neighbor in the same row. See [below](#-window-layout-dwindle-and-swapping-like-hyprland). |
| `Win+↑` / `Win+↓` | Swap with the window above / below |
| `Win+Shift+←↑→↓` | Raw GlazeWM move (like `movewindow`; may reshape the layout) |
| `Win+M` | Flip the split direction for the next window |

### 🔢 Workspaces

| Shortcut | Action |
|---|---|
| `Alt+1` … `Alt+9`, `Alt+0` | Go to workspace 1…10 (safe to hammer as fast as you like) |
| `Alt+Shift+1` … `Alt+Shift+0` | Send the window there **and stay where you are** (`movetoworkspacesilent`) |

### 🖥️ Monitors

| Shortcut | Action | On Hyprland |
|---|---|---|
| `Win+Ctrl+L` | External monitor only | `Win+L` (extonly) |
| `Win+Shift+L` | Extend to both monitors | `Win+Shift+L` (bothmons) |
| `Ctrl+Alt+M` | Windows display switcher | monitors.sh |

`Win+L` can't be rebound: Windows reserves it for locking.

### 🎵 Media, brightness, screenshots

| Shortcut | Action |
|---|---|
| `Ctrl+Alt+P` | Play / pause |
| `Ctrl+Alt+N` | Next track |
| `Ctrl+Alt+]` or `Ctrl+Alt+'` | Brightness +5 % (with an on-screen tooltip) |
| `Ctrl+Alt+[` or `Ctrl+Alt+;` | Brightness −5 % |
| `Ctrl+Alt+U` | Region screenshot to the clipboard (was grim + slurp) |
| `Ctrl+Alt+0` | Night light settings |

The keyboard's own media and brightness keys keep working.

### ⚙️ GlazeWM

| Shortcut | Action |
|---|---|
| `Ctrl+Alt+Shift+R` | Reload the config |
| `Ctrl+Alt+Shift+E` | Quit GlazeWM cleanly (restores every window) |
| `Ctrl+Alt+Shift+Space` | Pause / resume tiling |
| `Ctrl+Alt+Shift+U` | Bring back "lost" windows ([why](#lost-windows)) |

---

## 🌀 Window layout: dwindle and swapping like Hyprland

GlazeWM tiles like i3 (rows and columns), not like Hyprland/bspwm (a binary tree). Two pieces of `ahk/glaze-bridge.ps1` make it behave like my Hyprland:

**Dwindle autotiling.** Every time a tiled window gets focus, the helper looks at its shape: if it's wider than tall, the next window opens **beside** it; if it's taller than wide, **below** it.

```
1 window          2 windows          3 windows
+-----------+     +-----+-----+      +-----+-----+
|           |     |     |     |      |     |  2  |
|     1     | --> |  1  |  2  | -->  |  1  +-----+
|           |     |     |     |      |     |  3  |
+-----------+     +-----+-----+      +-----+-----+
```

**`Win+arrows` like `swapwindow`.** GlazeWM has no "swap", and its `move` turned my two columns into full-width rows. The helper decides instead:

- **Neighbor in the same row/column** → the two windows **swap**.
- **Window in another column** (`Win+←/→`) → it acts like pressing the key **twice**: the window leaves its column and lands **under** the window on the other side, splitting it:
  ```
  +-----+-----+                 +-----+-----+
  |  A  |     |                 |     |  B  |
  +-----+  B  |   Win+→ on C    |  A  +-----+
  |  C  |     |   ----------->  |     |  C  |
  +-----+-----+                 +-----+-----+
  ```
- **Only two windows** → flips them between two rows and two columns.
- **No window in that direction** → nothing happens, so the layout never collapses into full-width rows.

---

## 📊 The bar (Zebar, Waybar style)

Same modules as my Waybar:

| Left | Center | Right |
|---|---|---|
| Workspaces 1–5 (active in blue, click to switch) | time `\|` date `\|` Ecuador time | CPU · RAM |
| System tray | | Volume (scroll = change, right-click = mute, click = mixer) |
| Spotify (click = play/pause, middle = next, right = previous; italic when paused) | | Battery (green / blue / peach / red) |

The bar is docked: Windows reserves its 35 px so windows never slide under it, and fullscreen apps cover it. The workspace dots talk to GlazeWM directly over its WebSocket (Zebar's own GlazeWM module froze under fast switching), so they stay in sync.

Compared to Waybar it lacks CPU temperature and brightness: Zebar has no source for them.

---

## 💻 Terminal: Alacritty + zsh on Arch

`Win+Enter` (or `Alt+Enter`) opens **Alacritty** running **zsh inside WSL2 Arch Linux**, starting in my Windows user folder.

- **Fast**: the window appears in ~30–130 ms and the shell is ready in ~0.75 s (PowerShell 7 took ~1.2 s). AutoHotkey keeps Arch running in the background, so there's never a WSL cold start.
- **Looks like my kitty**: JetBrainsMono NF SemiBold 16, white text on solid black, my palette, block cursor, padding 5, no title bar. `Ctrl+Shift+N` opens another window; GlazeWM tiles them (Alacritty has no tabs/splits).
- **Prompt like PowerShell's**: in Windows folders it shows the Windows path, e.g. `C:\Users\ricar>`; in Linux folders, the Linux path (`/home/ricky>`).
- **Lean zsh** (no Oh My Zsh, starts in ~25 ms): menu completion that ignores case, shared history, `↑` searches history for what you've typed, `Ctrl+←/→` jump words, title = current folder.
- **`ls` = `ls -a`** with clean colors: folders on `C:\` are blue without the green "world-writable" background and files aren't painted green as executables. `ll` and `la` too.
- **Windows tools without `.exe`**: if a command doesn't exist in Linux, zsh runs its Windows version, so `keytool`, `java`, `javac`… just work.
- **`cmd` habits work**: `type file` shows a file, plus `cls`, `copy`, `move`, `ren`, `del`, `md`, `rd`.
- **Shared clipboard** with Windows (`win32yank`), and `pwsh` is one word away when I need PowerShell.

Behind it: Arch user `ricky` with `sudo`, set as the default WSL user and distro; `/mnt/c` mounted with `umask=022` so folders don't show as world-writable (without `fmask`, so Windows `.exe` files stay runnable); `~/.zshrc` is a symlink to `zsh/zshrc` in this repo.

---

## 📝 Neovim

My Linux config, **unchanged where possible**, with plugins pinned to the same versions through `lazy-lock.json`: Cyberdream, Telescope, nvim-tree, Treesitter, lualine, bufferline, harpoon, hop, LuaSnip, nvim-surround, autopairs, LSP (lua_ls, pyright, clangd, cssls/html, typescript-tools) and format-on-save.

**One config, two systems.** On Windows `%LOCALAPPDATA%\nvim` and inside Arch `~/.config/nvim` both point to `nvim/`, so editing it once changes both. Each system has its own plugins and language servers, and the config detects where it runs:

| Command | Windows | Arch |
|---|---|---|
| `:Kitty` / `:Term` | Alacritty with zsh in the file's folder | same |
| `:GCC` | compile with MSYS2 gcc, run in a new Alacritty | compile with gcc, run in a new Alacritty |
| Telescope projects | `C:/coding` | `/mnt/c/coding` |

Other Windows fixes: lazy.nvim installs itself on first launch, and `hop.nvim` points to the maintained fork `smoka7/hop.nvim` (the original repo was deleted).

Main keys (leader = `Space`): `Ctrl+F` find files · `Space ff/fg/fb/fe/fp` Telescope files/grep/buffers/browser/parent · `Space e` nvim-tree · `Ctrl+S` save + format · `gd` / `K` / `gi` LSP.

---

## 🔷 PowerShell 7

`ls` behaves like on Arch: it's GNU `ls` from Git for Windows instead of `Get-ChildItem`, with `ls` = `ls -a`, columns and the same colors as zsh. `ll` and `la` work too. The profile lives in `powershell/profile.ps1`; `$PROFILE` just loads it.

---

## 🧰 WezTerm (alternative terminal)

Still configured with the same look, for when I want tabs and splits like kitty: `Ctrl+Alt+T`/`O` split beside, `Ctrl+Alt+Y` split below, `Ctrl+Shift+arrows` move between splits, `Ctrl+Shift+Alt+arrows` resize, `Ctrl+Shift+W` close, `Ctrl+Shift+T` new tab, `Ctrl+PageUp/Down` switch tabs, and `Ctrl+Shift+L` picks a shell (Arch zsh, PowerShell 7, PowerShell 5.1, cmd). It opens PowerShell 7 by default and needs the **nightly** build: the 2024 stable one garbles text on resize. It takes ~2 s to open, which is why Alacritty is the main terminal.

---

## 🔧 Under the hood

### Fast, unbreakable `Alt+number`

On Hyprland the compositor owns workspaces, so mashing `Alt+1234 4321` is fine. On Windows, GlazeWM hides and shows every window by hand, and fast keys used to get lost, leave focus on a hidden window and freeze the bar. Now:

1. **AutoHotkey** catches `Alt+number` and writes it to a named pipe (~1 ms).
2. **`glaze-bridge.ps1`** keeps a WebSocket open to GlazeWM and sends the switch in **~46 ms** (launching `glazewm.exe` per key took ~270 ms). If GlazeWM is still busy, only the **last** key is sent. When you stop, it re-sends the final workspace once or twice, because GlazeWM sometimes jumps back after a burst.
3. **The bar** reads workspaces straight from GlazeWM's WebSocket and reconnects by itself.

### Lost windows

GlazeWM hides (cloaks) windows on workspaces you aren't viewing. If it's killed instead of quit, they stay open but invisible. `scripts/uncloak.ps1` finds them and shows them again so GlazeWM picks them back up. It runs automatically every time GlazeWM starts, and on demand with `Ctrl+Alt+Shift+U`. Quit with `Ctrl+Alt+Shift+E` to avoid it altogether.

### Small things that add up

- Floating windows use `shown_on_top`, so an installer never hides behind a tiled window.
- Alacritty uses the normal window frame and GlazeWM strips the title bar, which avoids a border flash when the mouse moves focus.
- The terminal font family is `JetBrainsMono NF`, the name the Nerd Font registers on Windows; `JetBrainsMono Nerd Font` silently falls back to another font in Alacritty.

---

## 📦 Installation

**1. Apps**

```powershell
winget install glzr-io.glazewm
winget install glzr-io.zebar
winget install AutoHotkey.AutoHotkey
winget install Alacritty.Alacritty
winget install Flow-Launcher.Flow-Launcher
winget install Neovim.Neovim
winget install Git.Git
winget install Microsoft.PowerShell
winget install DEVCOM.JetBrainsMonoNerdFont
winget install wez.wezterm.nightly   # optional
```

**2. Clone and link the configs** (junctions need no admin rights). Clone into `C:\Users\<you>\Win2Hyprland`, then:

```powershell
New-Item -ItemType Junction -Path "$env:USERPROFILE\.glzr"          -Target "$env:USERPROFILE\Win2Hyprland\glzr"
New-Item -ItemType Junction -Path "$env:APPDATA\alacritty"          -Target "$env:USERPROFILE\Win2Hyprland\alacritty"
New-Item -ItemType Junction -Path "$env:LOCALAPPDATA\nvim"          -Target "$env:USERPROFILE\Win2Hyprland\nvim"
New-Item -ItemType Junction -Path "$env:USERPROFILE\.config\wezterm" -Target "$env:USERPROFILE\Win2Hyprland\wezterm"
Set-Content $PROFILE ". '$env:USERPROFILE\Win2Hyprland\powershell\profile.ps1'"
```

**3. Arch Linux in WSL**

```powershell
wsl --install -d archlinux
wsl --set-default archlinux
```

Inside Arch (as root): `pacman -Syu zsh git sudo`, create your user in the `wheel` group with zsh as its shell, give `wheel` sudo, and put this in `/etc/wsl.conf`:

```ini
[user]
default=ricky

[automount]
options = "metadata,umask=022"
```

Then, as your user: `ln -s /mnt/c/Users/<you>/Win2Hyprland/zsh/zshrc ~/.zshrc`.

**4. Neovim tools**

```powershell
winget install BurntSushi.ripgrep.MSVC
winget install sharkdp.fd
winget install JohnnyMorganz.StyLua
winget install LuaLS.lua-language-server
npm install -g pyright vscode-langservers-extracted prettier
```

gcc and clangd come from [MSYS2](https://www.msys2.org/) UCRT64. Inside Arch: `pacman -S neovim ripgrep fd gcc clang lua-language-server stylua pyright prettier nodejs npm`, then `ln -s /mnt/c/Users/<you>/Win2Hyprland/nvim ~/.config/nvim`. Run `nvim --headless "+Lazy! restore" +qa` on each side to fetch the plugins.

**5. Start GlazeWM.** It launches Zebar and AutoHotkey, and AutoHotkey launches the helper.

> Some paths contain my username (`C:/Users/ricar/...`, the Arch user `ricky`): GlazeWM's app launchers, the AutoHotkey script path, Alacritty's start folder and `zsh/zshrc`. Replace them with yours. Monitor indices in `bind_to_monitor` depend on your displays (`glazewm query monitors`).

---

## 🗂️ Repository layout

```
Win2Hyprland/
├── glzr/
│   ├── glazewm/config.yaml    ← tiling, gaps, workspaces, window rules, binds
│   └── zebar/
│       ├── settings.json      ← which bar starts
│       └── waybar/            ← the bar: bar.html · styles.css · zpack.json
├── ahk/
│   ├── hotkeys.ahk            ← Alt+number, Win+arrows, media, brightness, screenshots
│   └── glaze-bridge.ps1       ← fast workspaces · dwindle autotiling · Hyprland-style swap
├── scripts/
│   ├── uncloak.ps1            ← recover lost windows
│   └── autotile.py            ← standalone autotiler (not used; the bridge does it)
├── alacritty/alacritty.toml   ← main terminal
├── zsh/zshrc                  ← zsh for WSL Arch
├── powershell/profile.ps1     ← PowerShell 7 profile (Arch-like ls)
├── nvim/                      ← Neovim (Windows + Arch)
├── wezterm/wezterm.lua        ← alternative terminal (tabs/splits)
├── hyprland-reference.conf    ← my original Hyprland config
└── CLAUDE.md                  ← notes for editing all this with Claude Code
```

---

## 🚧 Known limitations

- **Blur**: Windows doesn't allow it.
- **`Win+L`**: reserved by Windows.
- **Swapping across columns** is emulated on top of GlazeWM (it has no binary tree), so a few unusual layouts can still need a second key press. A true BSP window manager such as Komorebi would remove that limitation.
- **No equivalent yet** for hiding the bar (`Win+P`), the power menu (`Win+Escape`), switching audio output (`Ctrl+Alt+V`) and the power profile (`Ctrl+Alt+B`).
- **clangd on Windows** needs an up-to-date MSYS2 (`pacman -Syu`); inside Arch it works out of the box.

<div align="center">

*Made because I missed Hyprland.* 🐧

</div>

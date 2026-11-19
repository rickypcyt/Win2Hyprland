# Win2Hyprland — notas para Claude

Escritorio de Windows 11 configurado para parecerse al Hyprland que usaba en Linux.
El usuario habla español. Cada cambio pedido = editar el archivo, aplicarlo y hacer commit.
Repo público: https://github.com/rickypcyt/Win2Hyprland. Hacer `git push` solo cuando el usuario lo pida. Si cambian atajos o funciones, actualizar también `README.md`.

## Qué hay y dónde

| Herramienta | Papel (equivalente Linux) | Archivo en este repo | Cómo lo lee el programa |
|---|---|---|---|
| GlazeWM 3.x | gestor de ventanas tiling (Hyprland) | `glzr/glazewm/config.yaml` | `~\.glzr` es un **junction** a `Win2Hyprland\glzr` |
| Zebar | barra superior (Waybar) | `glzr/zebar/waybar/` (pack propio: `bar.html` lógica, `styles.css` colores Catppuccin, `zpack.json` tamaño/permisos); `glzr/zebar/settings.json` elige el pack | mismo junction |
| AutoHotkey v2 | atajos que GlazeWM no puede: multimedia, brillo, capturas | `ahk/hotkeys.ahk` | lo lanza GlazeWM en `startup_commands` |
| Alacritty | terminal principal (kitty), abre en ~50 ms | `alacritty/alacritty.toml` | `%APPDATA%\alacritty` es un **junction** a `Win2Hyprland\alacritty` (creado fuera del paquete). Win+Enter / Win+C lo lanzan con la ruta 8.3 `C:/PROGRA~1/ALACRI~1/ALACRI~1.EXE` |
| WezTerm | terminal alternativa (pestañas/divisiones) | `wezterm/wezterm.lua` | `~\.config\wezterm` es un **junction** a `Win2Hyprland\wezterm` |
| Neovim 0.12 | editor (misma config que en Linux) | `nvim/` (lazy.nvim; `lazy-lock.json` fija versiones) | `%LOCALAPPDATA%\nvim` es un **junction** a `Win2Hyprland\nvim`; plugins en `%LOCALAPPDATA%\nvim-data\lazy` |
| Flow Launcher | lanzador (rofi) | *no está en el repo* | `%LOCALAPPDATA%\FlowLauncher\Settings\Settings.json` (Flow lo sobrescribe al salir: cerrar Flow antes de editarlo) |

`hyprland-reference.conf` es la config original de Hyprland, solo como referencia de qué atajo hacía qué.

## Aplicar cambios

- **GlazeWM**: `glazewm command wm-reload-config` (o Ctrl+Alt+Shift+R). Si algo falla, mirar `glzr/glazewm/errors.log`.
  Comprobar estado: `glazewm query monitors` / `glazewm query workspaces`.
  CLI: `C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe`.
- **Zebar**: `taskkill /IM zebar.exe /F` y `zebar`. Errores en `glzr/zebar/errors.log`.
  Para ver el resultado: captura de la franja superior con System.Drawing (`CopyFromScreen`) y leer el PNG.
  En `settings.json` el pack local se llama por su `name` a secas (`"waybar"`, no `local.waybar`).
  Proveedores disponibles (zebar 3.3): glazewm, systray, media, date, cpu, memory, audio, battery, network, disk, weather, keyboard, host, ip. No hay temperatura ni brillo.
  **Workspaces de la barra NO usan el proveedor `glazewm` de Zebar** (se congelaba con cambios rápidos): `bar.html` abre su propio WebSocket a `ws://localhost:6123` (IPC de GlazeWM), `sub -e all` + `query monitors` en cada evento, sondeo cada 500 ms y reconexión. Mantenerlo así.
  Abrir cosas desde la barra = `zebar.shellExec`, y el programa/argumentos deben estar permitidos en `privileges.shellCommands` de `zpack.json`.
- **AutoHotkey**: ejecutar de nuevo `ahk\hotkeys.ahk` (tiene `#SingleInstance Force`, reemplaza la instancia).
- **WezTerm**: recarga solo al guardar. Nightly (`wez.wezterm.nightly`): la estable de 2024 traía un conpty viejo que rompía el texto al redimensionar. Shell por defecto: `pwsh` (el usuario prefirió PowerShell 7 a WSL); Arch en el menú Ctrl+Shift+L. Ya no hay keepalive de WSL en `hotkeys.ahk`. Terminal principal: Alacritty (`pwsh`, `working_directory = C:\Users\ricar`, fuente `JetBrainsMono NF`: en Windows **no existe** la familia "JetBrainsMono Nerd Font" y Alacritty, a diferencia de WezTerm, no la resuelve).

## Convenciones de atajos (mantenerlas)

- `Win` = apps y acciones de ventana · `Alt` = workspaces · `Ctrl+Alt` = multimedia/utilidades (AHK) · `Ctrl+Alt+Shift` = control de GlazeWM.
- Un atajo vive en **un solo sitio**: GlazeWM si lanza algo o maneja ventanas, AHK si necesita enviar teclas/WMI. Antes de añadir uno, buscar que no esté ya en el otro archivo.
- Windows no deja usar `Win+L` (bloqueo).
- **Excepción: `Alt+1..0` (cambiar de workspace) está en AHK, no en GlazeWM.** El usuario los pulsa muy rápido en ráfagas (1234 4321…); en GlazeWM eso perdía teclas y dejaba el foco en ventanas ocultas. No volver a ponerlos en `config.yaml`. (`Alt+Shift+N` sí sigue en GlazeWM.)
  Camino: `hotkeys.ahk` (`WsGo`, `Critical`, conexión persistente) escribe el número en la named pipe `\\.\pipe\win2hyprland-ws` → `ahk/glaze-bridge.ps1` (C# vía Add-Type, lo arranca hotkeys.ahk, mutex de instancia única) lo manda por un WebSocket abierto a `127.0.0.1:6123`. ~46 ms frente a ~270 ms lanzando `glazewm.exe`. El puente coalesce (solo la última tecla) y al parar "asienta" re-mandando el último workspace a los 90 y 220 ms, porque GlazeWM a veces vuelve a un workspace anterior tras una ráfaga. Si el puente no responde, `WsGoSlow` usa `glazewm.exe`. Log: `%TEMP%\glaze-bridge.log` (`GLAZE_BRIDGE_VERBOSE=1` para traza).
- **Autotiling (dwindle de Hyprland)** también vive en `glaze-bridge.ps1`: con `focus_changed` de una ventana en mosaico manda `set-tiling-direction horizontal` si es más ancha que alta, `vertical` si no (50 ms de calma, nunca durante un cambio de workspace). Por eso `Win+M` (toggle-tiling-direction) solo afecta hasta el siguiente cambio de foco.

## Trampas conocidas

- **⚠ Lo que Claude escribe en `%LOCALAPPDATA%` / `%APPDATA%` NO llega al sitio real.** La app de Claude es un paquete MSIX: Windows redirige esas escrituras a `%LOCALAPPDATA%\Packages\AnthropicPBC.Claude_*\LocalCache\...`, que solo ve la propia app. Crear junctions, instalar plugins de nvim, etc. bajo AppData hay que hacerlo **fuera del paquete**: escribir un `.cmd` en `.tmp/` (gitignored) y lanzarlo con una tarea puntual (`schtasks /Create /TN W2H_x /TR <cmd> /SC ONCE /ST 23:59 /F`, `schtasks /Run`, luego `/Delete`), escribiendo el log en `.tmp/`. Si se ensucia la carpeta privada, borrar allí la copia. Las rutas fuera de AppData (`~\.glzr`, `~\.config`, este repo, `C:\msys64`) no tienen este problema.
- **Neovim**: `localhost` tarda ~2 s (prueba IPv6) en clientes .NET; usar `127.0.0.1` para el WebSocket de GlazeWM. Los LSP de npm (`pyright`, `vscode-*-language-server`) funcionan vía sus `.cmd`. `typescript-tools` usa el TypeScript del proyecto (el global es TS 7, sin `tsserver`). clangd viene de MSYS2 (`C:\msys64\ucrt64\bin`).

- `shell-exec` de GlazeWM: usar barras `/` en rutas y evitar rutas con espacios y comillas (da "command doesn't have an ending `\"`"). Si la ruta tiene espacios, buscar una alternativa (App Paths, alias en PATH, URI `ms-settings:` …).
- Atajos `lwin+…` de GlazeWM sustituyen a los de Windows (Win+E, Win+V, Win+S…).
- `bind_to_monitor` usa el índice de `glazewm query monitors`, que cambia si se desconecta el HDMI.
- El brillo por WMI solo funciona en la pantalla del portátil.
- La regla `ignore` para `window_process: zebar` es obligatoria; sin ella la barra aparece como ventana en el mosaico.
- **WSL Arch** (`archlinux`, distro por defecto de WSL): usuario `ricky` (zsh, grupo `wheel` con sudo vía `/etc/sudoers.d/wheel`), usuario por defecto en `/etc/wsl.conf`, Oh My Zsh clonado en `~/.oh-my-zsh` con la plantilla de `.zshrc`. Para tareas de root sin contraseña: `wsl -d archlinux -u root -- ...`. Lanzar `wsl` desde PowerShell, no desde Git Bash (Git Bash reescribe las rutas `/mnt/c/...`).
- **Neovim en Arch**: `~/.config/nvim` de ricky es un symlink a `/mnt/c/Users/ricar/Win2Hyprland/nvim` (misma config). Plugins aparte en `~/.local/share/nvim/lazy`. La config distingue con `vim.fn.has("win32")`: `:Kitty`/`:Term`/`:GCC` usan `wezterm-gui --domain local` en Windows y `wezterm.exe --domain WSL:archlinux` en Arch; telescope-project usa `C:/coding` o `/mnt/c/coding`. Herramientas en Arch vía pacman (neovim, rg, fd, gcc, clang, lua-language-server, stylua, pyright, prettier) + `npm -g vscode-langservers-extracted`. clangd sí funciona en Arch (en Windows falla hasta actualizar MSYS2).
- **zsh (Arch)**: `~/.zshrc` de ricky es symlink a `zsh/zshrc` del repo (LF obligatorio, ver `.gitattributes`). Prompt propio estilo PowerShell (`w2h_prompt_path`: `/mnt/c/...` → `C:\...>`), con `ZSH_THEME=""`. Powerlevel10k sigue clonado en `~/.oh-my-zsh/custom/themes/powerlevel10k`, pero no se usa porque al usuario no le gustó. Escribir rutas con `\` en archivos del repo con el editor, no con heredocs de Git Bash ni Python inline, que se comen las barras invertidas. Para correr cosas en Arch usar scripts `.sh` en `.tmp/` con `wsl -d archlinux -u ricky -- bash /mnt/c/.../script.sh`: pasar comandos inline desde PowerShell/Git Bash los rompe.
- **Colores de ls en Arch**: `/etc/wsl.conf` tiene `[automount] options = "metadata,umask=022"` (carpetas de /mnt/c sin 777 → sin fondo verde). **No añadir `fmask=111`**: quita el bit de ejecución a los `.exe` de Windows y rompe la interop (`wezterm.exe`, `win32yank.exe`). Además `zsh/zshrc` fija `ow`/`tw` a azul sin fondo y `ex=00`. Cambios en wsl.conf requieren `wsl --terminate archlinux`.
- **Velocidad de WezTerm**: zsh sin Oh My Zsh (`zsh/zshrc` ligero, ~25 ms frente a ~330 ms); dominio WSL definido a mano en `wezterm.lua` (no usar `wezterm.default_wsl_domains()`: ejecuta `wsl.exe` en cada arranque); `hotkeys.ahk` deja un `sleep infinity` (argv0 `w2h-keepalive`) para que Arch no se apague y no haya arranque en frío de la VM. Lo que queda (~2 s hasta ver la ventana) es el arranque del propio `wezterm-gui`; en Windows `wezterm-gui start` no reutiliza el proceso abierto. Medir desde la app de Claude es poco fiable (el socket de WezTerm vive en AppData, redirigido por MSIX).
- **Herramientas de Windows en zsh**: `command_not_found_handler` en `zsh/zshrc` ejecuta `<cmd>.exe` (o `.cmd`/`.bat` vía `cmd.exe /c`) si el comando no existe en Linux (p. ej. `keytool`, `java` del JDK de Windows). Usa `whence -p`, nunca `$commands[...]` (forzaría rehash de ~50 carpetas de Windows por 9p). Ojo: los shims sin extensión de npm global de Windows (`%APPDATA%\npm\tsc`) sí son "comandos de Linux" y se ejecutan con el node de Arch (falla `tsc` de TS 7). `ls` = `ls -a`. El prompt se queda como está (el usuario lo confirmó).
- **Win+flechas = swap** (en AHK → pipe `swap <dir>` → `Swap()` en `glaze-bridge.ps1`): sube desde la ventana con foco solo a través de envoltorios de un hijo (los `split` que crea `set-tiling-direction` del autotiling), y si en el grupo real del mismo eje la vecina (desenvuelta) es una ventana en mosaico, manda `move --direction` (que entonces intercambia). Si no, no hace nada: el `move` de GlazeWM sin vecina convertía columnas en filas a todo lo ancho. Limitación aceptada por el usuario: no intercambia entre grupos distintos (p. ej. columna izquierda ↔ ventana de la columna derecha). `Win+Shift+flechas` siguen en GlazeWM (`move`). `scripts/autotile.py` (de otra fuente) está desactivado: duplicaba el autotiling del puente.
- **⚠ NUNCA matar GlazeWM a la fuerza** (`Stop-Process glazewm, glazewm-watcher`): las ventanas de workspaces ocultos se quedan "cloaked" (abiertas pero invisibles) y el usuario las pierde. Cerrar con `glazewm command wm-exit`, que las restaura. Si pasa: `powershell -File scripts/uncloak.ps1` (Windows PowerShell 5.1, no pwsh: necesita IInspectable) las des-oculta vía `IApplicationView::SetCloak` (GUIDs de Win11 24H2+, no documentado) excluyendo las que GlazeWM gestiona y las apps de sistema. `hotkeys.ahk` lo ejecuta 3 s después de arrancar y con Ctrl+Alt+Shift+U.
- **Commits: `git add` con rutas concretas, nunca `git add -A`.** El usuario guarda cosas suyas dentro de esta carpeta (p. ej. `Claude outputs/`, ya en `.gitignore`) y el repo es público.
- **PowerShell 7**: `$PROFILE` (`Documents\PowerShell\Microsoft.PowerShell_profile.ps1`, fuera del repo) solo hace dot-source de `powershell/profile.ps1`. Ahí `ls`/`ll`/`la` usan GNU `ls.exe` de `C:\Program Files\Git\usr\bin` con LS_COLORS fijo (tabla de dircolors + ow/tw azul, ex=00), igual que en zsh.
- **Win+flechas entre columnas**: si no hay vecina en el mismo grupo pero sí una ventana en esa dirección (geometría), `move` normal. Excepción: si la ventana está sola en su columna (padre con 2 hijos y al lado un grupo), `SwapAcrossGroups` saca la ventana más cercana del grupo y las intercambia (pausa el autotiling con `swapping`); el último paso para re-apilar no funciona aún y queda como 3 columnas. Probar estas cosas en el workspace 9 es poco fiable si el usuario está usando el PC (le cambia de workspace y el foco sigue al ratón).
- **Doble pulsación entre columnas (arreglado)**: el primer `move` solo sacaba la ventana de su envoltorio del autotiling y la dejaba como columna nueva; `LandedNextToGroup` lo detecta y el puente manda el segundo `move` solo (máx. 2). Sin probar en escritorio real (el usuario lo estaba usando); pedirle confirmación.

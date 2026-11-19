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
| WezTerm | terminal (kitty) | `wezterm/wezterm.lua` | `~\.config\wezterm` es un **junction** a `Win2Hyprland\wezterm` |
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
- **WezTerm**: recarga solo al guardar. Nightly (`wez.wezterm.nightly`): la estable de 2024 traía un conpty viejo que rompía el texto al redimensionar. Shell por defecto: WSL `archlinux` (zsh + Oh My Zsh) si existe, si no `pwsh`. Lo que deba correr en Windows se lanza con `wezterm-gui start --domain local -- ...` (Win+C nvim, `:GCC`).

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

# Win2Hyprland — notas para Claude

Escritorio de Windows 11 configurado para parecerse al Hyprland que usaba en Linux.
El usuario habla español. Cada cambio pedido = editar el archivo, aplicarlo y hacer commit.

## Qué hay y dónde

| Herramienta | Papel (equivalente Linux) | Archivo en este repo | Cómo lo lee el programa |
|---|---|---|---|
| GlazeWM 3.x | gestor de ventanas tiling (Hyprland) | `glzr/glazewm/config.yaml` | `~\.glzr` es un **junction** a `Win2Hyprland\glzr` |
| Zebar | barra superior (Waybar) | `glzr/zebar/waybar/` (pack propio: `bar.html` lógica, `styles.css` colores Catppuccin, `zpack.json` tamaño/permisos); `glzr/zebar/settings.json` elige el pack | mismo junction |
| AutoHotkey v2 | atajos que GlazeWM no puede: multimedia, brillo, capturas | `ahk/hotkeys.ahk` | lo lanza GlazeWM en `startup_commands` |
| WezTerm | terminal (kitty) | `wezterm/wezterm.lua` | `~\.config\wezterm` es un **junction** a `Win2Hyprland\wezterm` |
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
- **WezTerm**: recarga solo al guardar.

## Convenciones de atajos (mantenerlas)

- `Win` = apps y acciones de ventana · `Alt` = workspaces · `Ctrl+Alt` = multimedia/utilidades (AHK) · `Ctrl+Alt+Shift` = control de GlazeWM.
- Un atajo vive en **un solo sitio**: GlazeWM si lanza algo o maneja ventanas, AHK si necesita enviar teclas/WMI. Antes de añadir uno, buscar que no esté ya en el otro archivo.
- Windows no deja usar `Win+L` (bloqueo).
- **Excepción: `Alt+1..0` (cambiar de workspace) está en AHK, no en GlazeWM.** El usuario los pulsa muy rápido en ráfagas (1234 4321…); en GlazeWM eso perdía teclas y dejaba el foco en ventanas ocultas. `WsGo`/`WsFlush` en `hotkeys.ahk` coalescen las pulsaciones y llaman a `glazewm command focus --workspace N` solo con la última. No volver a ponerlos en `config.yaml`. (`Alt+Shift+N` sí sigue en GlazeWM.)

## Trampas conocidas

- `shell-exec` de GlazeWM: usar barras `/` en rutas y evitar rutas con espacios y comillas (da "command doesn't have an ending `\"`"). Si la ruta tiene espacios, buscar una alternativa (App Paths, alias en PATH, URI `ms-settings:` …).
- Atajos `lwin+…` de GlazeWM sustituyen a los de Windows (Win+E, Win+V, Win+S…).
- `bind_to_monitor` usa el índice de `glazewm query monitors`, que cambia si se desconecta el HDMI.
- El brillo por WMI solo funciona en la pantalla del portátil.
- La regla `ignore` para `window_process: zebar` es obligatoria; sin ella la barra aparece como ventana en el mosaico.

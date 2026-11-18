# Dotfiles de Windows (estilo Hyprland)

Escritorio de Windows 11 configurado para parecerse al Hyprland que usaba en Linux.
El usuario habla español. Cada cambio pedido = editar el archivo, aplicarlo y hacer commit.

## Qué hay y dónde

| Herramienta | Papel (equivalente Linux) | Archivo en este repo | Cómo lo lee el programa |
|---|---|---|---|
| GlazeWM 3.x | gestor de ventanas tiling (Hyprland) | `glzr/glazewm/config.yaml` | `~\.glzr` es un **junction** a `dotfiles\glzr` |
| Zebar | barra superior (Waybar) | `glzr/zebar/` (`settings.json` elige el widget pack) | mismo junction |
| AutoHotkey v2 | atajos que GlazeWM no puede: multimedia, brillo, capturas | `ahk/hotkeys.ahk` | lo lanza GlazeWM en `startup_commands` |
| WezTerm | terminal (kitty) | `wezterm/wezterm.lua` | `~\.config\wezterm` es un **junction** a `dotfiles\wezterm` |
| Flow Launcher | lanzador (rofi) | *no está en el repo* | `%LOCALAPPDATA%\FlowLauncher\Settings\Settings.json` (Flow lo sobrescribe al salir: cerrar Flow antes de editarlo) |

`hyprland-reference.conf` es la config original de Hyprland, solo como referencia de qué atajo hacía qué.

## Aplicar cambios

- **GlazeWM**: `glazewm command wm-reload-config` (o Ctrl+Alt+Shift+R). Si algo falla, mirar `glzr/glazewm/errors.log`.
  Comprobar estado: `glazewm query monitors` / `glazewm query workspaces`.
  CLI: `C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe`.
- **Zebar**: se reinicia con GlazeWM, o `taskkill /IM zebar.exe /F` y `zebar`.
- **AutoHotkey**: ejecutar de nuevo `ahk\hotkeys.ahk` (tiene `#SingleInstance Force`, reemplaza la instancia).
- **WezTerm**: recarga solo al guardar.

## Convenciones de atajos (mantenerlas)

- `Win` = apps y acciones de ventana · `Alt` = workspaces · `Ctrl+Alt` = multimedia/utilidades (AHK) · `Ctrl+Alt+Shift` = control de GlazeWM.
- Un atajo vive en **un solo sitio**: GlazeWM si lanza algo o maneja ventanas, AHK si necesita enviar teclas/WMI. Antes de añadir uno, buscar que no esté ya en el otro archivo.
- Windows no deja usar `Win+L` (bloqueo).

## Trampas conocidas

- `shell-exec` de GlazeWM: usar barras `/` en rutas y evitar rutas con espacios y comillas (da "command doesn't have an ending `\"`"). Si la ruta tiene espacios, buscar una alternativa (App Paths, alias en PATH, URI `ms-settings:` …).
- Atajos `lwin+…` de GlazeWM sustituyen a los de Windows (Win+E, Win+V, Win+S…).
- `bind_to_monitor` usa el índice de `glazewm query monitors`, que cambia si se desconecta el HDMI.
- El brillo por WMI solo funciona en la pantalla del portátil.
- La regla `ignore` para `window_process: zebar` es obligatoria; sin ella la barra aparece como ventana en el mosaico.

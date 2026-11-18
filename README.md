# Win2Hyprland

**Mi config de Hyprland, literal, puesta en Windows 11.**

Usaba Linux con Hyprland y me pasé a Windows. Pero no quería perder la forma de trabajar: ventanas en mosaico automático, workspaces con `Alt+número`, todo con el teclado y una barra arriba igual que mi Waybar. Este repo es eso: cogí mi `hyprland.conf` y mi Waybar y los traduje atajo por atajo a herramientas que funcionan en Windows.

Va rápido y funciona bien en el día a día. Puedo hacer mi manía de pulsar `Alt+1234 4321` a toda velocidad sin que nada se rompa (más abajo explico cómo).

`hyprland-reference.conf` es mi config original de Hyprland, para comparar.

---

## Qué usa (y a qué equivale en Linux)

| En Hyprland | En Windows | Archivo |
|---|---|---|
| Hyprland (tiling, workspaces, atajos) | [GlazeWM](https://github.com/glzr-io/glazewm) | `glzr/glazewm/config.yaml` |
| Waybar | [Zebar](https://github.com/glzr-io/zebar) con un pack propio | `glzr/zebar/waybar/` |
| `playerctl`, `swayosd`, `grim`/`slurp`… | [AutoHotkey v2](https://www.autohotkey.com/) | `ahk/hotkeys.ahk` |
| kitty | [WezTerm](https://wezfurlong.org/wezterm/) | `wezterm/wezterm.lua` |
| rofi | [Flow Launcher](https://www.flowlauncher.com/) | — (su propia config) |

## Cómo se ve

- **Mosaico automático** con `gaps_in = 5` y `gaps_out = 10`, igual que en Hyprland.
- **Esquinas redondeadas**, sin bordes ni barras de título.
- **Sin transparencia**: todas las ventanas opacas (en Hyprland tenía `inactive_opacity = 0.9`, aquí lo quité).
- **El foco sigue al ratón**, como `follow_mouse = 1`.
- **Workspaces fijos por monitor:** el 1 en el monitor externo y del 2 al 5 en la pantalla del portátil, como tenía con `workspace = N, monitor:…`.
- **Barra superior negra de 35 px**, con JetBrainsMono Nerd Font y colores Catppuccin Mocha, igual que mi Waybar.

---

## Atajos

La lógica es la misma que en Hyprland:

- **`Win`** (`$mainMod`): abrir apps y manejar ventanas.
- **`Alt`** (`$altMod`): workspaces.
- **`Ctrl+Alt`**: multimedia, brillo y utilidades.
- **`Ctrl+Alt+Shift`**: control del propio gestor de ventanas.

### Aplicaciones

| Atajo | Abre | En Hyprland era |
|---|---|---|
| `Win+Enter` | WezTerm | kitty |
| `Win+Space` | Flow Launcher (también `Alt+Space`) | rofi -show drun |
| `Win+E` | Explorador de archivos | thunar |
| `Win+F` | Brave | brave |
| `Win+C` | WezTerm con Neovim | kitty nvim |
| `Win+O` | Obsidian | obsidian |
| `Win+S` | Spotify | spotify |
| `Win+Z` | WhatsApp | zapzap |
| `Win+Shift+D` | Discord | discord |
| `Win+N` | Ajustes de Wi-Fi | nmtui |
| `Win+B` | Ajustes de Bluetooth | blueman-manager |
| `Win+V` | Mezclador de volumen | pavucontrol |
| `Win+T` | Ajustes del touchpad | toggle-touchpad.sh |
| `Win+Q` | Bloquear la sesión | hyprlock |

### Ventanas

| Atajo | Acción |
|---|---|
| `Alt+W` | Cerrar la ventana |
| `Win+I` | Alternar flotante / mosaico |
| `Win+↑` | Pantalla completa |
| `Win+←` / `Win+→` | Mover la ventana a izquierda / derecha |
| `Win+Shift+←↑→↓` | Mover la ventana en esa dirección |
| `Win+M` | Cambiar la dirección del mosaico (horizontal / vertical) |

### Workspaces

| Atajo | Acción |
|---|---|
| `Alt+1` … `Alt+9`, `Alt+0` | Ir al workspace 1…10 |
| `Alt+Shift+1` … `Alt+Shift+0` | Mover la ventana a ese workspace e ir con ella |

### Monitores

| Atajo | Acción | En Hyprland era |
|---|---|---|
| `Win+Ctrl+L` | Solo el monitor externo | `Win+L` (extonly) |
| `Win+Shift+L` | Extender a los dos monitores | `Win+Shift+L` (bothmons) |
| `Ctrl+Alt+M` | Selector de pantallas de Windows | monitors.sh |

`Win+L` no se puede usar porque Windows lo reserva para bloquear la sesión.

### Multimedia, brillo y capturas (AutoHotkey)

| Atajo | Acción |
|---|---|
| `Ctrl+Alt+P` | Reproducir / pausar |
| `Ctrl+Alt+N` | Siguiente canción |
| `Ctrl+Alt+]` o `Ctrl+Alt+'` | Subir el brillo un 5 % |
| `Ctrl+Alt+[` o `Ctrl+Alt+;` | Bajar el brillo un 5 % |
| `Ctrl+Alt+U` | Captura de una zona al portapapeles (antes grim + slurp) |
| `Ctrl+Alt+0` | Ajustes de luz nocturna |

Las teclas multimedia y de brillo del teclado funcionan como siempre.

### GlazeWM

| Atajo | Acción |
|---|---|
| `Ctrl+Alt+Shift+R` | Recargar la config |
| `Ctrl+Alt+Shift+E` | Salir de GlazeWM |
| `Ctrl+Alt+Shift+Space` | Pausar / reanudar el mosaico |

---

## La barra (Zebar, estilo Waybar)

Tiene los mismos módulos que mi Waybar:

- **Izquierda:**
  - Workspaces del 1 al 5, siempre visibles. El activo aparece en azul y puedes hacer clic para cambiar.
  - Bandeja del sistema.
  - Spotify: clic para pausar o reanudar, clic central para la siguiente, clic derecho para la anterior. En pausa sale en cursiva.
- **Centro:** hora `|` fecha `|` hora de Ecuador.
- **Derecha:**
  - CPU y RAM.
  - Volumen: la rueda lo sube o baja, el clic derecho silencia y el clic izquierdo abre el mezclador.
  - Batería, con colores según la carga: verde, azul, melocotón o rojo.

La barra queda anclada arriba y Windows le reserva su espacio, así que las ventanas nunca se meten debajo.

Comparada con mi Waybar le faltan la temperatura de CPU y el brillo, porque Zebar no tiene de dónde sacar esos datos.

---

## Por qué no se rompe al pulsar rápido

En Hyprland podía machacar `Alt+1234 4321` y no pasaba nada, porque el propio compositor gestiona los workspaces. En Windows, GlazeWM tiene que ocultar y mostrar cada ventana a mano. Si las teclas llegan más rápido de lo que tarda, se perdían pulsaciones, el foco se quedaba en una ventana oculta y la barra se desincronizaba.

Lo solucioné con dos cambios:

1. **`Alt+número` lo gestiona AutoHotkey, no GlazeWM.** Si GlazeWM está libre, el cambio se manda al instante. Si está ocupado, solo se guarda la última tecla pulsada y se manda al terminar. Las intermedias se descartan, así que no se acumula nada y siempre terminas en el último workspace que pulsaste.
2. **La barra habla directamente con GlazeWM** por su WebSocket (`localhost:6123`), sin pasar por el módulo de Zebar, que se congelaba. Vuelve a consultar el estado con cada evento, comprueba cada 500 ms por si se pierde alguno y se reconecta sola si GlazeWM se reinicia.

Probado con ráfagas simuladas de hasta 49 pulsaciones en menos de 300 ms. Siempre termina en el workspace correcto, con el foco bien puesto y la barra sincronizada.

---

## Instalación

```powershell
winget install glzr-io.glazewm
winget install glzr-io.zebar
winget install AutoHotkey.AutoHotkey
winget install wez.wezterm
winget install Flow-Launcher.Flow-Launcher
winget install Neovim.Neovim
winget install DEVCOM.JetBrainsMonoNerdFont
```

Clona el repo en `C:\Users\<tu usuario>\Win2Hyprland` y enlaza las carpetas de config con junctions (no necesitan permisos de administrador):

```powershell
New-Item -ItemType Junction -Path "$env:USERPROFILE\.glzr" -Target "$env:USERPROFILE\Win2Hyprland\glzr"
New-Item -ItemType Junction -Path "$env:USERPROFILE\.config\wezterm" -Target "$env:USERPROFILE\Win2Hyprland\wezterm"
```

Después abre GlazeWM. Él lanza Zebar y los atajos de AutoHotkey.

Algunas rutas de `glzr/glazewm/config.yaml` llevan mi usuario (`C:/Users/ricar/...`): el script de AutoHotkey, Brave, Obsidian, Discord y Flow Launcher. Cámbialas por las tuyas. Los índices de monitor de `bind_to_monitor` dependen de tu configuración de pantallas; los ves con `glazewm query monitors`.

## Estructura

```
Win2Hyprland/
├── glzr/
│   ├── glazewm/config.yaml   ← tiling, gaps, workspaces, atajos
│   └── zebar/
│       ├── settings.json     ← qué barra arranca
│       └── waybar/           ← la barra: bar.html, styles.css, zpack.json
├── ahk/hotkeys.ahk           ← Alt+número, multimedia, brillo, capturas
├── wezterm/wezterm.lua       ← terminal
├── hyprland-reference.conf   ← mi config original de Hyprland
└── CLAUDE.md                 ← notas para editar la config con Claude Code
```

## Lo que no se puede igualar

- **Blur:** Windows no lo permite.
- **Dwindle:** GlazeWM no divide en espiral automáticamente; coloca cada ventana nueva en la dirección actual del mosaico (`Win+M` la cambia).
- **`Win+L`:** reservado por Windows.
- **Sin equivalente por ahora:** ocultar la barra (`Win+P`), menú de apagado (`Win+Escape`), cambiar la salida de audio (`Ctrl+Alt+V`) y perfil de energía (`Ctrl+Alt+B`).

"""
GlazeWM autotiling (port de la idea de i3-autolayout / dwindle de Hyprland).

Cada vez que cambia el foco o se gestiona una ventana nueva, mira la ventana
enfocada: si es mas ancha que alta -> split horizontal (lado a lado),
si no -> split vertical (arriba/abajo). Asi el siguiente split reparte bien.

Requisitos:  pip install websockets
Uso:         pythonw autotile.py   (sin consola)
"""

import asyncio
import json
import socket
import sys

import websockets

URI = "ws://localhost:6123"   # puerto IPC por defecto de GlazeWM
LOCK_PORT = 61237             # solo para impedir que corran dos instancias
WIDTH_MULTIPLIER = 1.0        # >1.0 favorece splits horizontales (util en ultrawide)
EVENTS = "focus_changed window_managed"


def pick_direction(win: dict) -> str:
    w, h = win.get("width", 0), win.get("height", 0)
    return "horizontal" if w * WIDTH_MULTIPLIER > h else "vertical"


def get_tiling_window(data: dict) -> dict | None:
    win = data.get("focusedContainer") or data.get("managedWindow")
    if not win or win.get("type") != "window":
        return None
    if (win.get("state") or {}).get("type") != "tiling":
        return None  # ignorar flotantes / fullscreen / minimizadas
    return win


async def run() -> None:
    last: dict[str, str] = {}  # id de ventana -> ultima direccion aplicada
    async with websockets.connect(URI) as ws:
        await ws.send(f"sub --events {EVENTS}")
        async for raw in ws:
            msg = json.loads(raw)
            if msg.get("messageType") != "event_subscription":
                continue
            win = get_tiling_window(msg.get("data") or {})
            if not win:
                continue
            direction = pick_direction(win)
            if last.get(win["id"]) == direction:
                continue
            last[win["id"]] = direction
            await ws.send(f"command set-tiling-direction {direction}")


async def main() -> None:
    # Reintenta si GlazeWM aun no ha arrancado o se reinicia.
    while True:
        try:
            await run()
        except (OSError, websockets.ConnectionClosed):
            await asyncio.sleep(2)


def single_instance() -> socket.socket | None:
    # GlazeWM relanza startup_commands en cada arranque: evita duplicados.
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.bind(("127.0.0.1", LOCK_PORT))
    except OSError:
        return None
    return s


if __name__ == "__main__":
    lock = single_instance()
    if lock is None:
        sys.exit(0)
    asyncio.run(main())

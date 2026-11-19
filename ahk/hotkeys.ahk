#Requires AutoHotkey v2.0
#SingleInstance Force
; ============================================================
; Atajos que GlazeWM no puede hacer (multimedia, brillo, capturas).
; Lo arranca GlazeWM (general.startup_commands).
; Win+W y Win+Enter ahora los maneja GlazeWM.
; Tras editar: volver a ejecutar el script (SingleInstance Force lo reemplaza).
;
; Modificadores AHK:  # = Win   ! = Alt   ^ = Ctrl   + = Shift
; ============================================================

; ---------- Workspaces (ALT 1..0) ----------
; Vía rápida: el número se escribe en la named pipe de glaze-bridge.ps1,
; que lo manda a GlazeWM por un WebSocket ya abierto (~1 ms aquí + lo que
; tarde GlazeWM). El puente coalesce las ráfagas (Alt+1234 4321 rápido):
; si GlazeWM está ocupado solo manda la última tecla.
; Si el puente no está disponible, se usa la vía lenta (glazewm.exe, ~270 ms).
global WsTarget := "", WsSent := "", WsBusy := false
GLAZE_CLI := "C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe"
WS_PIPE := "\\.\pipe\win2hyprland-ws"

; Arrancar el puente (si ya hay uno corriendo, el nuevo sale solo).
Run 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' A_ScriptDir '\glaze-bridge.ps1"', , "Hide"

; Mantener WSL Arch encendido: Alacritty abre zsh en Arch, y si Arch está apagado
; la primera terminal tarda varios segundos en arrancar la VM.
; Un "sleep infinity" oculto lo mantiene vivo; si ya existe, no se crea otro.
Run 'wsl.exe -d archlinux -u ricky --exec bash -c "pgrep -f ^w2h-keepalive >/dev/null || exec -a w2h-keepalive sleep infinity"', , "Hide"

; ---------- Ventanas perdidas ----------
; Si GlazeWM se cerró mal, las ventanas de otros workspaces se quedan ocultas
; (abiertas pero invisibles). scripts\uncloak.ps1 las vuelve a mostrar y GlazeWM
; las recoge. Se ejecuta al arrancar (este script lo lanza GlazeWM) y con
; Ctrl+Alt+Shift+U. Windows PowerShell 5.1 a propósito: pwsh 7 no puede.
RecoverWindows() {
    Run 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' A_ScriptDir '\..\scripts\uncloak.ps1"', , "Hide"
}
SetTimer RecoverWindows, -3000      ; 3 s tras arrancar, cuando GlazeWM ya gestiona sus ventanas
^!+u::RecoverWindows()


global WsPipe := ""

; Escribe una línea en la pipe del puente. false si el puente no responde.
BridgeSend(line) {
    ; Critical: una pulsación no puede interrumpir a otra, así que los mensajes
    ; llegan al puente en el mismo orden en que se pulsaron.
    Critical
    global WsPipe, WS_PIPE
    msg := line "`n"
    buf := Buffer(StrPut(msg, "UTF-8") - 1)
    StrPut(msg, buf, "UTF-8")
    loop 3 {
        try {
            if !IsObject(WsPipe)
                WsPipe := FileOpen(WS_PIPE, "w")   ; conexión persistente
            if DllCall("WriteFile", "ptr", WsPipe.Handle, "ptr", buf, "uint", buf.Size
                     , "uint*", &written := 0, "ptr", 0)
                return true
        }
        WsPipe := ""                               ; puente reiniciado: reconectar
        Sleep 5
    }
    return false
}

WsGo(name) {
    if !BridgeSend(name)
        WsGoSlow(name)                             ; puente caído: vía lenta
}

; ---------- Win+flechas = swapwindow de Hyprland ----------
; Intercambia la ventana con su vecina del mismo grupo; si no hay, no hace nada
; (el "move" de GlazeWM creaba filas a todo lo ancho). Lo decide glaze-bridge.ps1.
; Win+Shift+flechas siguen en GlazeWM (move = movewindow de Hyprland).
; Win+←/→ = como pulsar dos veces (el puente repite el movimiento si la ventana
; pasó a otra columna; así queda debajo de la ventana destino de un solo toque).
#Left::BridgeSend("swap2 left")
#Right::BridgeSend("swap2 right")
#Up::BridgeSend("swap up")
#Down::BridgeSend("swap down")

WsGoSlow(name) {
    global WsTarget
    WsTarget := name
    SetTimer WsFlush, -1
}

!1::WsGo("1")
!2::WsGo("2")
!3::WsGo("3")
!4::WsGo("4")
!5::WsGo("5")
!6::WsGo("6")
!7::WsGo("7")
!8::WsGo("8")
!9::WsGo("9")
!0::WsGo("10")

WsFlush() {
    global WsTarget, WsSent, WsBusy, GLAZE_CLI
    if WsBusy
        return
    WsBusy := true
    try {
        while (WsTarget != WsSent) {
            t := WsTarget
            RunWait '"' GLAZE_CLI '" command focus --workspace ' t, , "Hide"
            WsSent := t
        }
    }
    WsBusy := false
    ; Si el usuario cambió de workspace por otro medio (clic en la barra),
    ; olvidar el último enviado para no saltarse la próxima pulsación.
    SetTimer () => (WsBusy ? 0 : (WsSent := "")), -400
}

; ---------- Multimedia (CTRL ALT P / N) ----------
^!p::Send "{Media_Play_Pause}"
^!n::Send "{Media_Next}"

; ---------- Brillo (CTRL ALT ] [ ' ;) ----------
^!]::ChangeBrightness(5)
^![::ChangeBrightness(-5)
^!'::ChangeBrightness(5)
^!;::ChangeBrightness(-5)

; ---------- Capturas (CTRL ALT U = región → portapapeles) ----------
^!u::Send "#+s"

; ---------- Luz nocturna (CTRL ALT 0) → ajustes ----------
^!0::Run "ms-settings:nightlight"

; Brillo de la pantalla del portátil (no funciona en monitores externos).
ChangeBrightness(delta) {
    wmi := ComObjGet("winmgmts:\\.\root\WMI")
    cur := 50
    for m in wmi.ExecQuery("SELECT CurrentBrightness FROM WmiMonitorBrightness WHERE Active=TRUE") {
        cur := m.CurrentBrightness
        break
    }
    new := Max(0, Min(100, cur + delta))
    for m in wmi.ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods WHERE Active=TRUE")
        m.WmiSetBrightness(1, new)
    ToolTip "☀ " new "%"
    SetTimer () => ToolTip(), -900
}

; ============================================================
; KOMOREBI (alternativa a GlazeWM)
; ============================================================
; Estos atajos SOLO se activan si komorebi.exe está corriendo. Con GlazeWM,
; AutoHotkey los deja pasar y GlazeWM hace lo suyo (config.yaml).
; Alternar: scripts\use-komorebi.ps1 / scripts\use-glazewm.ps1
; Mismos atajos que en GlazeWM; Komorebi usa layout BSP (árbol binario tipo
; bspwm/dwindle) y su "move" INTERCAMBIA ventanas, como swapwindow de Hyprland.

KOMOREBIC := "C:\Program Files\komorebi\bin\komorebic-no-console.exe"
KomorebiOn() => ProcessExist("komorebi.exe")
K(args) {
    global KOMOREBIC
    Run '"' KOMOREBIC '" ' args, , "Hide"
}

#HotIf KomorebiOn()

; ---------- Aplicaciones ----------
#Enter::Run '"C:\Program Files\Alacritty\alacritty.exe"'
!Enter::Run '"C:\Program Files\Alacritty\alacritty.exe"'
#Space::Run EnvGet("LOCALAPPDATA") '\FlowLauncher\Flow.Launcher.exe'
#c::Run '"C:\Program Files\Alacritty\alacritty.exe" --working-directory C:\Users\ricar -e nvim'
#e::Run "explorer.exe"
#f::Run EnvGet("LOCALAPPDATA") '\BraveSoftware\Brave-Browser\Application\brave.exe'
#o::Run EnvGet("LOCALAPPDATA") '\Programs\Obsidian\Obsidian.exe'
#s::Run "spotify:"
#z::Run "whatsapp:"
#+d::Run EnvGet("LOCALAPPDATA") '\Discord\Update.exe --processStart Discord.exe'
#n::Run "ms-settings:network-wifi"
#b::Run "ms-settings:bluetooth"
#v::Run "ms-settings:apps-volume"
#t::Run "ms-settings:devices-touchpad"
#q::DllCall("LockWorkStation")

; ---------- Ventanas ----------
!w::K("close")
#i::K("toggle-float")
#+f::K("toggle-monocle")            ; ventana sola ocupando todo el workspace
#m::K("flip-layout horizontal")
; Win+flechas: en BSP, "move" intercambia con la ventana de ese lado (swapwindow)
#Left::K("move left")
#Right::K("move right")
#Up::K("move up")
#Down::K("move down")
; Win+Shift+flechas: mover el foco (sin ratón)
#+Left::K("focus left")
#+Right::K("focus right")
#+Up::K("focus up")
#+Down::K("focus down")

; ---------- Workspaces ----------
!1::K("focus-named-workspace 1")
!2::K("focus-named-workspace 2")
!3::K("focus-named-workspace 3")
!4::K("focus-named-workspace 4")
!5::K("focus-named-workspace 5")
!6::K("focus-named-workspace 6")
!7::K("focus-named-workspace 7")
!8::K("focus-named-workspace 8")
!9::K("focus-named-workspace 9")
!0::K("focus-named-workspace 10")
; Alt+Shift+número: mandar la ventana sin seguirla (movetoworkspacesilent)
!+1::K("send-to-named-workspace 1")
!+2::K("send-to-named-workspace 2")
!+3::K("send-to-named-workspace 3")
!+4::K("send-to-named-workspace 4")
!+5::K("send-to-named-workspace 5")
!+6::K("send-to-named-workspace 6")
!+7::K("send-to-named-workspace 7")
!+8::K("send-to-named-workspace 8")
!+9::K("send-to-named-workspace 9")
!+0::K("send-to-named-workspace 10")

; ---------- Monitores ----------
#^l::Run "DisplaySwitch.exe /external"
#+l::Run "DisplaySwitch.exe /extend"
^!m::Run "DisplaySwitch.exe"

; ---------- Control de Komorebi ----------
^!+r::K("retile")
^!+Space::K("toggle-pause")
^!+e::Run 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' A_ScriptDir '\..\scripts\use-glazewm.ps1"', , "Hide"

#HotIf

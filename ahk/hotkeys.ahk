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
; GlazeWM se bugea si recibe Alt+número más rápido de lo que tarda en
; cambiar de workspace (pierde teclas o deja el foco en una ventana oculta).
; Aquí se coalescen: mientras GlazeWM está ocupado, las pulsaciones
; intermedias se descartan y al terminar se manda solo la última.
; Sin retardo cuando GlazeWM está libre.
global WsTarget := "", WsSent := "", WsBusy := false
GLAZE_CLI := "C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe"

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

WsGo(name) {
    global WsTarget
    WsTarget := name
    SetTimer WsFlush, -1
}

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

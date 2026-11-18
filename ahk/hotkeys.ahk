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

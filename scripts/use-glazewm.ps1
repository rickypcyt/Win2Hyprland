# ============================================================
# Volver de Komorebi a GlazeWM (sin perder ventanas)
# ============================================================
# Uso:  pwsh -File scripts\use-glazewm.ps1   (con Komorebi también: Ctrl+Alt+Shift+E)
# ============================================================
$repo      = Split-Path $PSScriptRoot -Parent
$komorebic = 'C:\Program Files\komorebi\bin\komorebic.exe'

# 1. Parar Komorebi: "stop" vuelve a mostrar todas las ventanas que tenía ocultas.
if (Get-Process komorebi -ErrorAction SilentlyContinue) {
    & $komorebic stop | Out-Null
    $t = 0; while ((Get-Process komorebi -ErrorAction SilentlyContinue) -and $t -lt 50) { Start-Sleep -Milliseconds 200; $t++ }
}

# 2. Arrancar GlazeWM (lanza Zebar y AutoHotkey por su cuenta).
if (-not (Get-Process glazewm -ErrorAction SilentlyContinue)) {
    Start-Process 'C:\Program Files\glzr.io\GlazeWM\glazewm.exe'
}

# 3. Por si alguna ventana se quedó oculta.
Start-Sleep -Seconds 3
powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'scripts\uncloak.ps1') | Out-Null

"GlazeWM activo. Probar Komorebi: scripts\use-komorebi.ps1"

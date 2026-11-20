# Reinicia Zebar para que vuelva a reservar sus 35px arriba en cada pantalla.
#
# Al cambiar de pantallas (extender, solo portátil, solo BenQ...) Zebar pierde
# la reserva (dockToEdge) y las ventanas se ponen encima de la barra.
# Lo lanza ahk/hotkeys.ahk cada vez que Windows avisa de un cambio de pantallas,
# da igual cómo se haya cambiado (pantalla, Win+Shift+L, Win+P...).

$ErrorActionPreference = 'SilentlyContinue'

# Evitar dos reinicios a la vez
$mutex = [Threading.Mutex]::new($false, 'Local\win2hyprland-restart-bar')
if (-not $mutex.WaitOne(0)) { exit }

try {
    function Get-Monitors { @((glazewm query monitors | ConvertFrom-Json).data.monitors) }
    function Count-Reserved { @(Get-Monitors | Where-Object { $_.workingRect.top -gt $_.y }).Count }

    $want = (Get-Monitors).Count
    if (-not $want) { exit }

    # A veces una pantalla se queda sin reserva (carrera al arrancar): se reintenta.
    for ($try = 0; $try -lt 3; $try++) {
        Stop-Process -Name zebar -Force
        Start-Sleep -Seconds 1
        Start-Process zebar
        for ($i = 0; $i -lt 16; $i++) {       # máx. ~8 s por intento
            Start-Sleep -Milliseconds 500
            if ((Count-Reserved) -ge $want) { break }
        }
        if ((Count-Reserved) -ge $want) { break }
    }
    glazewm command wm-redraw | Out-Null
}
finally { $mutex.ReleaseMutex() }

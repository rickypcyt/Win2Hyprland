# pantalla: modo de pantallas de Windows + en qué pantalla va cada workspace de GlazeWM.
# Ejecuta "pantalla ayuda" para ver el uso. Sin argumentos lo que hace es enseñar el estado.
#
# El reparto se guarda en bind_to_monitor de glzr/glazewm/config.yaml, así se mantiene
# al reiniciar GlazeWM y al desconectar/conectar pantallas.

$ErrorActionPreference = 'Stop'
$Config = Join-Path $PSScriptRoot '..\glzr\glazewm\config.yaml'

# ---------------------------------------------------------------- pantallas
$Screens = [ordered]@{
    benq   = @{ Hw = 'BNQ78FA'; Label = 'BenQ' }
    laptop = @{ Hw = 'NCP002D'; Label = 'Portátil' }
}
$ByHw = @{}; foreach ($k in $Screens.Keys) { $ByHw[$Screens[$k].Hw] = $k }

# ---------------------------------------------------------------- comandos
# Modos de pantalla: qué hace DisplaySwitch y cuántas pantallas verá GlazeWM.
$Modes = [ordered]@{
    laptop = @{ Switch = '/internal'; Count = 1; Desc = 'solo la pantalla del portátil' }
    benq   = @{ Switch = '/external'; Count = 1; Desc = 'solo el BenQ ("mostrar solo en 2")' }
    extend = @{ Switch = '/extend';   Count = 2; Desc = 'extender a las dos (mantiene el reparto)' }
    clone  = @{ Switch = '/clone';    Count = 1; Desc = 'duplicar' }
}
# Presets: extienden a las dos pantallas y reparten los workspaces.
$Presets = [ordered]@{
    trabajo  = @{ Desc = '1-4 BenQ, 5 portátil'; Map = @{ '1'='benq'; '2'='benq';   '3'='benq';   '4'='benq';   '5'='laptop' } }
    visuales = @{ Desc = '1 BenQ, 2-5 portátil'; Map = @{ '1'='benq'; '2'='laptop'; '3'='laptop'; '4'='laptop'; '5'='laptop' } }
}
$Aliases = @{
    l='laptop'; portatil='laptop'; internal='laptop'
    b='benq'; externo='benq'; external='benq'
    e='extend'; extender='extend'; ambas='extend'; dual='extend'
    c='clone'; clonar='clone'; duplicar='clone'
    t='trabajo'; v='visuales'
    s='estado'; status='estado'
    h='ayuda'; help='ayuda'; '-h'='ayuda'; '--help'='ayuda'; '/?'='ayuda'
}
$Words = @($Modes.Keys) + @($Presets.Keys) + 'estado', 'ayuda'

# ---------------------------------------------------------------- salida
function Say($text, $color = 'Gray') { Write-Host $text -ForegroundColor $color }
function Fail($text) { Write-Host "error: $text" -ForegroundColor Red; exit 1 }

function Show-Help {
    Say 'pantalla — modo de pantallas + workspaces de GlazeWM' White
    Say ''
    Say 'Uso:' White
    Say '  pantalla                      estado actual'
    Say '  pantalla <modo|preset> [ws=pantalla ...]'
    Say '  pantalla <ws>=<pantalla> ...  solo cambiar el reparto'
    Say ''
    Say 'Modos:' White
    foreach ($k in $Modes.Keys)   { Say ('  {0,-10} {1}' -f $k, $Modes[$k].Desc) }
    Say ''
    Say 'Presets (extienden y reparten):' White
    foreach ($k in $Presets.Keys) { Say ('  {0,-10} {1}' -f $k, $Presets[$k].Desc) }
    Say ''
    Say 'Reparto a mano: 1=b 2=l ...  (b = BenQ, l = portátil; los demás no cambian)' White
    Say ''
    Say 'Ejemplos:' White
    Say '  pantalla visuales             extender: 1 en el BenQ, 2-5 en el portátil'
    Say '  pantalla benq                 solo el BenQ (todos los workspaces van ahí)'
    Say '  pantalla extend 1=b 3=b       extender y poner 1 y 3 en el BenQ'
    Say '  pantalla 5=b                  mover el 5 al BenQ'
    Say ''
    Say 'Vale cualquier prefijo que no sea ambiguo (vis, tra, ext) y las letras l, b, e, c, t, v.' DarkGray
}

# Resolver una palabra: alias, exacta o prefijo único.
function Resolve-Word($w) {
    $w = $w.ToLower()
    if ($Aliases.ContainsKey($w)) { return $Aliases[$w] }
    if ($Words -contains $w) { return $w }
    $hits = @($Words | Where-Object { $_.StartsWith($w) })
    if ($hits.Count -eq 1) { return $hits[0] }
    if ($hits.Count -gt 1) { Fail "'$w' es ambiguo: $($hits -join ', ')" }
    Fail "no conozco '$w'. Opciones: $($Words -join ', '). Mira: pantalla ayuda"
}

function Resolve-Screen($s) {
    switch -Regex ($s.ToLower()) {
        '^(b|benq|ext|externo|external)$'    { return 'benq' }
        '^(l|laptop|p|portatil|internal)$'   { return 'laptop' }
    }
    Fail "pantalla desconocida '$s' (usa b o l)"
}

# ---------------------------------------------------------------- GlazeWM
function Get-Monitors {
    $res = glazewm query monitors | ConvertFrom-Json
    # GlazeWM numera las pantallas por posición (izquierda→derecha, arriba→abajo)
    @($res.data.monitors | Sort-Object x, y)
}

function Get-ScreenName($m) { if ($ByHw[$m.hardwareId]) { $ByHw[$m.hardwareId] } else { $m.hardwareId } }

function Get-CurrentMode($monitors) {
    $names = @($monitors | ForEach-Object { Get-ScreenName $_ })
    if ($names.Count -ge 2) { 'extend' } elseif ($names -contains 'laptop') { 'laptop' } else { 'benq' }
}

# Índice de GlazeWM de cada pantalla. Con las dos se calcula por posición;
# con una sola se usa el orden habitual (BenQ 0, portátil 1).
function Get-Indexes($monitors) {
    $idx = @{ benq = 0; laptop = 1 }
    if (@($monitors | Where-Object { $ByHw[$_.hardwareId] }).Count -ge 2) {
        for ($i = 0; $i -lt $monitors.Count; $i++) {
            $n = $ByHw[$monitors[$i].hardwareId]; if ($n) { $idx[$n] = $i }
        }
    }
    $idx
}

# Lee el reparto guardado: workspace → pantalla.
function Read-Binds($idx) {
    $byIdx = @{}; foreach ($k in $idx.Keys) { $byIdx[$idx[$k]] = $k }
    $binds = [ordered]@{}; $ws = $null; $inWs = $false
    foreach ($line in Get-Content $Config) {
        if ($line -match '^workspaces:') { $inWs = $true; continue }
        if ($inWs -and $line -match '^\S') { break }
        if ($line -match "^\s*-\s*name:\s*'?(\w+)'?") { $ws = $Matches[1] }
        elseif ($ws -and $line -match '^\s*bind_to_monitor:\s*(\d+)') { $binds[$ws] = $byIdx[[int]$Matches[1]] }
    }
    $binds
}

function Write-Binds($target, $idx) {
    $path = (Resolve-Path $Config).Path
    $raw = [IO.File]::ReadAllText($path)
    $nl = if ($raw.Contains("`r`n")) { "`r`n" } else { "`n" }
    $lines = $raw -split "`r?`n"
    $ws = $null; $inWs = $false; $done = @{}
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^workspaces:') { $inWs = $true; continue }
        if (-not $inWs) { continue }
        if ($line -match '^\S') { break }
        if ($line -match "^\s*-\s*name:\s*'?(\w+)'?") { $ws = $Matches[1] }
        elseif ($ws -and $target.Contains($ws) -and $line -match '^(\s*bind_to_monitor:\s*)\d+(.*)$') {
            $lines[$i] = "$($Matches[1])$($idx[$target[$ws]])$($Matches[2])"
            $done[$ws] = $true
        }
    }
    $missing = @($target.Keys | Where-Object { -not $done[$_] })
    if ($missing) { Fail "workspace sin bind_to_monitor en config.yaml: $($missing -join ', ') (añádelo allí primero)" }
    [IO.File]::WriteAllText($path, ($lines -join $nl), [Text.UTF8Encoding]::new($false))
    glazewm command wm-reload-config | Out-Null
}

# Mueve ya cada workspace a su pantalla (solo con las dos encendidas).
function Move-Workspaces($target) {
    $monitors = Get-Monitors
    $focused = $null
    foreach ($m in $monitors) { foreach ($w in $m.children) { if ($w.hasFocus) { $focused = $w.name } } }
    $moved = 0
    foreach ($ws in $target.Keys) {
        $now = Get-Monitors
        $cur = $now | Where-Object { $_.children.name -contains $ws } | Select-Object -First 1
        $dst = $now | Where-Object { $_.hardwareId -eq $Screens[$target[$ws]].Hw } | Select-Object -First 1
        if (-not $cur -or -not $dst -or $cur.hardwareId -eq $dst.hardwareId) { continue }
        $dx = $dst.x - $cur.x; $dy = $dst.y - $cur.y
        $dir = if ([math]::Abs($dx) -ge [math]::Abs($dy)) { if ($dx -gt 0) { 'right' } else { 'left' } }
               else { if ($dy -gt 0) { 'down' } else { 'up' } }
        glazewm command focus --workspace $ws | Out-Null
        glazewm command move-workspace --direction $dir | Out-Null
        $moved++
    }
    if ($focused -and $moved) { glazewm command focus --workspace $focused | Out-Null }
}

function Set-Mode($mode) {
    $info = $Modes[$mode]
    $current = Get-CurrentMode (Get-Monitors)
    if ($current -eq $mode -and $mode -ne 'clone') { Say "Ya está en modo $mode." DarkGray; return }
    Say "Cambiando a $mode…" Cyan
    DisplaySwitch.exe $info.Switch
    for ($i = 0; $i -lt 30; $i++) {          # esperar a GlazeWM, máx. ~15 s
        Start-Sleep -Milliseconds 500
        try { if ((Get-Monitors).Count -eq $info.Count) { break } } catch {}
    }
    Start-Sleep -Milliseconds 800             # que termine de recolocar
    # La barra (Zebar) la reinicia ahk/hotkeys.ahk al detectar el cambio de pantallas
    # (scripts/restart-bar.ps1), así funciona también con los atajos de teclado.
}

function Show-State {
    $monitors = Get-Monitors
    $idx = Get-Indexes $monitors
    $binds = Read-Binds $idx
    $mode = Get-CurrentMode $monitors

    $modeText = @{
        extend = 'las dos pantallas (extendido)'
        benq   = 'solo el BenQ'
        laptop = 'solo el portátil'
    }[$mode]
    function Label($n) { if ($Screens.Contains($n)) { $Screens[$n].Label } else { $n } }

    # 1) Qué pantallas hay encendidas
    Say ''
    Write-Host '  Pantallas encendidas: ' -NoNewline -ForegroundColor DarkGray
    Say $modeText White

    # 2) Dónde está cada workspace ahora mismo
    Say ''
    Say '  Workspaces ahora mismo:' DarkGray
    foreach ($m in $monitors) {
        Write-Host ('    {0,-10}' -f (Label (Get-ScreenName $m))) -NoNewline -ForegroundColor Cyan
        foreach ($w in $m.children) {
            $color = if ($w.hasFocus) { 'Green' } elseif ($w.isDisplayed) { 'White' } else { 'DarkGray' }
            Write-Host (' ' + $w.name) -NoNewline -ForegroundColor $color
        }
        Write-Host ''
    }
    Write-Host '    ' -NoNewline; Write-Host 'verde' -NoNewline -ForegroundColor Green
    Write-Host ' = donde estás, ' -NoNewline -ForegroundColor DarkGray
    Write-Host 'blanco' -NoNewline -ForegroundColor White
    Say ' = visible en otra pantalla, gris = oculto' DarkGray

    # 3) El reparto guardado para cuando hay dos pantallas
    $preset = $null
    foreach ($p in $Presets.Keys) {
        $map = $Presets[$p].Map
        if (-not @($map.Keys | Where-Object { $binds[$_] -ne $map[$_] })) { $preset = $p }
    }
    Say ''
    Write-Host '  Reparto con dos pantallas: ' -NoNewline -ForegroundColor DarkGray
    if ($preset) { Say $preset White } else { Say 'personalizado' White }
    foreach ($s in $Screens.Keys) {
        $list = @($binds.Keys | Where-Object { $binds[$_] -eq $s })
        $txt = if ($list) { $list -join ' ' } else { '(ninguno)' }
        Write-Host ('    {0,-10}' -f $Screens[$s].Label) -NoNewline -ForegroundColor Cyan
        Say " $txt"
    }
    if ($mode -eq 'extend') {
        Say '    Está aplicado.' DarkGray
    } else {
        Say "    Ahora no se usa: con $modeText todos los workspaces van a esa pantalla." DarkGray
        Say '    Se aplicará cuando extiendas (pantalla extend).' DarkGray
    }

    # 4) Qué puedes hacer
    Say ''
    Say '  Cambiar:  pantalla trabajo | visuales | benq | laptop | 5=b   (pantalla ayuda)' DarkGray
    Say ''
}

# ---------------------------------------------------------------- main
$mode = $null; $target = [ordered]@{}; $help = $false; $state = $false
foreach ($a in $args) {
    if ($a -match '^(\d+)[=:](\w+)$') {
        $wsName = $Matches[1]; $target[$wsName] = Resolve-Screen $Matches[2]; continue
    }
    $w = Resolve-Word $a
    if ($w -eq 'ayuda') { $help = $true }
    elseif ($w -eq 'estado') { $state = $true }
    elseif ($Presets.Contains($w)) {
        if ($mode -and $mode -ne 'extend') { Fail "'$w' necesita las dos pantallas; no se puede con '$mode'" }
        $mode = 'extend'
        $map = $Presets[$w].Map
        foreach ($k in ($map.Keys | Sort-Object)) { if (-not $target.Contains($k)) { $target[$k] = $map[$k] } }
    }
    else {
        if ($mode -and $mode -ne $w) { Fail "dos modos a la vez: $mode y $w" }
        $mode = $w
    }
}

if ($help) { Show-Help; exit 0 }
if (-not $mode -and -not $target.Count) { Show-State; exit 0 }

if ($mode) { Set-Mode $mode }

if ($target.Count) {
    $monitors = Get-Monitors
    Write-Binds $target (Get-Indexes $monitors)
    if ((Get-CurrentMode $monitors) -eq 'extend') { Move-Workspaces $target }
    else { Say 'Solo hay una pantalla: el reparto queda guardado y se aplica al extender (pantalla extend).' Yellow }
}

Show-State

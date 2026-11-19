# ============================================================
# Cambiar de GlazeWM a Komorebi (sin perder ventanas)
# ============================================================
# Uso:  pwsh -File scripts\use-komorebi.ps1
# Volver:  pwsh -File scripts\use-glazewm.ps1   (o Ctrl+Alt+Shift+E con Komorebi)
# ============================================================
$repo     = Split-Path $PSScriptRoot -Parent
$glazeCli = 'C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe'
$komorebic = 'C:\Program Files\komorebi\bin\komorebic.exe'

# 1. Cerrar GlazeWM limpiamente: wm-exit vuelve a mostrar todas las ventanas.
#    (Nunca matarlo a la fuerza: las ventanas de otros workspaces se quedarían ocultas.)
if (Get-Process glazewm -ErrorAction SilentlyContinue) {
    & $glazeCli command wm-exit | Out-Null
    $t = 0; while ((Get-Process glazewm -ErrorAction SilentlyContinue) -and $t -lt 50) { Start-Sleep -Milliseconds 200; $t++ }
}

# 1b. GlazeWM quita la barra de título (hide_title_bar) y al salir no la devuelve.
#     Komorebi no adopta ventanas sin ese estilo: devolvérselo a las ventanas
#     normales (redimensionables, visibles, sin propietario) que lo perdieron.
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public static class W2HFrames {
  public delegate bool EP(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EP f, IntPtr l);
  [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] static extern IntPtr GetWindow(IntPtr h, uint c);
  [DllImport("user32.dll")] static extern int GetWindowTextLength(IntPtr h);
  [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr h, int i);
  [DllImport("user32.dll")] static extern int SetWindowLong(IntPtr h, int i, int v);
  [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);
  const int GWL_STYLE = -16, WS_CAPTION = 0x00C00000, WS_THICKFRAME = 0x00040000, WS_POPUP = unchecked((int)0x80000000);
  public static int Restore() {
    int n = 0;
    EnumWindows((h, l) => {
      if (!IsWindowVisible(h) || GetWindow(h, 4) != IntPtr.Zero || GetWindowTextLength(h) == 0) return true;
      int s = GetWindowLong(h, GWL_STYLE);
      if ((s & WS_THICKFRAME) != 0 && (s & WS_CAPTION) != WS_CAPTION && (s & WS_POPUP) == 0) {
        SetWindowLong(h, GWL_STYLE, s | WS_CAPTION);
        SetWindowPos(h, IntPtr.Zero, 0, 0, 0, 0, 0x0027); // NOMOVE|NOSIZE|NOZORDER|FRAMECHANGED
        n++;
      }
      return true;
    }, IntPtr.Zero);
    return n;
  }

  // GlazeWM marca las ventanas como "en capas" (WS_EX_LAYERED) para la transparencia
  // y la deja puesta aunque la opacidad vuelva a 255. Komorebi no gestiona ventanas
  // en capas: quitar la marca SOLO si es ese resto (alfa por SetLayeredWindowAttributes = 255).
  [DllImport("user32.dll")] static extern bool GetLayeredWindowAttributes(IntPtr h, out uint k, out byte a, out uint f);
  public static int Unlayer() {
    int n = 0;
    EnumWindows((h, l) => {
      if (!IsWindowVisible(h) || GetWindow(h, 4) != IntPtr.Zero || GetWindowTextLength(h) == 0) return true;
      int ex = GetWindowLong(h, -20);
      if ((ex & 0x80000) == 0) return true;
      uint k, f; byte a;
      if (GetLayeredWindowAttributes(h, out k, out a, out f) && (f & 2) != 0 && a == 255 && (f & 1) == 0) {
        SetWindowLong(h, -20, ex & ~0x80000);
        SetWindowPos(h, IntPtr.Zero, 0, 0, 0, 0, 0x0027);
        n++;
      }
      return true;
    }, IntPtr.Zero);
    return n;
  }
}
"@
$fixed = [W2HFrames]::Restore()
if ($fixed) { "Barra de título devuelta a $fixed ventanas" }
$unl = [W2HFrames]::Unlayer()
if ($unl) { "Marca de transparencia quitada a $unl ventanas" }

# 2. Arrancar Komorebi con la config del repo.
$env:KOMOREBI_CONFIG_HOME = Join-Path $repo 'komorebi'
if (-not (Get-Process komorebi -ErrorAction SilentlyContinue)) {
    & $komorebic start --config (Join-Path $repo 'komorebi\komorebi.json') | Out-Null
}

# 3. Zebar: GlazeWM la cierra al salir (shutdown_commands); volver a abrirla.
Start-Sleep -Seconds 2
if (-not (Get-Process zebar -ErrorAction SilentlyContinue)) { Start-Process zebar }

# 4. AutoHotkey (lo lanza GlazeWM al arrancar; sigue vivo, pero por si acaso).
$ahk = Get-CimInstance Win32_Process -Filter "Name='AutoHotkey64.exe'" | Where-Object CommandLine -match 'hotkeys\.ahk'
if (-not $ahk) { Start-Process (Join-Path $repo 'ahk\hotkeys.ahk') }

# 5. Por si alguna ventana se quedó oculta.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'scripts\uncloak.ps1') | Out-Null

"Komorebi activo. Volver a GlazeWM: scripts\use-glazewm.ps1 o Ctrl+Alt+Shift+E"

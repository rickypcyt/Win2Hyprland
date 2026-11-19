# ============================================================
# Recuperar ventanas "perdidas" tras cerrar GlazeWM a la fuerza
# ============================================================
# GlazeWM oculta (cloak) las ventanas de los workspaces no visibles. Si se
# cierra bien (Ctrl+Alt+Shift+E) o se cuelga con su watcher vivo, las vuelve a
# mostrar. Si se mata a la fuerza junto con glazewm-watcher, se quedan
# ocultas: siguen abiertas pero invisibles.
#
# Este script las des-oculta con la misma API interna de Windows que usa
# GlazeWM (IApplicationView::SetCloak, no documentada; GUIDs de Windows 11).
#
# Uso (Windows PowerShell 5.1, NO pwsh 7: .NET moderno no soporta IInspectable):
#   powershell -File scripts\uncloak.ps1             (recupera todas)
#   powershell -File scripts\uncloak.ps1 -List       (solo lista)
#   powershell -File scripts\uncloak.ps1 -Match Code (solo las que coincidan)
# ============================================================
param([switch]$List, [string]$Match = '')

Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public static class Uncloak {
    [ComImport, Guid("6D5140C1-7436-11CE-8034-00AA006009FA"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IServiceProvider10 {
        [return: MarshalAs(UnmanagedType.IUnknown)]
        object QueryService(ref Guid service, ref Guid riid);
    }

    [ComImport, Guid("372E1D3B-38D3-42E4-A15B-8AB2B178F513"), InterfaceType(ComInterfaceType.InterfaceIsIInspectable)]
    interface IApplicationView {
        int SetFocus();
        int SwitchTo();
        int TryInvokeBack(IntPtr callback);
        int GetThumbnailWindow(out IntPtr hwnd);
        int GetMonitor(out IntPtr immersiveMonitor);
        int GetVisibility(out int visibility);
        int SetCloak(int cloakType, int unknown);
    }

    [ComImport, Guid("1841C6D7-4F9D-42C0-AF41-8747538F10E5"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IApplicationViewCollection {
        int GetViews(out IntPtr array);
        int GetViewsByZOrder(out IntPtr array);
        int GetViewsByAppUserModelId(string id, out IntPtr array);
        int GetViewForHwnd(IntPtr hwnd, out IApplicationView view);
    }

    public delegate bool EP(IntPtr h, IntPtr l);
    [DllImport("user32.dll")] static extern bool EnumWindows(EP f, IntPtr l);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] static extern IntPtr GetWindow(IntPtr h, uint c);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("dwmapi.dll")] static extern int DwmGetWindowAttribute(IntPtr h, int a, out int v, int s);

    // Ventanas de nivel superior, visibles, con título, ocultas por el shell (cloaked = 2).
    public static List<string> Lost() {
        var r = new List<string>();
        EnumWindows((h, l) => {
            if (!IsWindowVisible(h) || GetWindow(h, 4) != IntPtr.Zero) return true; // sin owner
            var sb = new StringBuilder(300); GetWindowText(h, sb, 300);
            if (sb.Length == 0) return true;
            int c = 0; DwmGetWindowAttribute(h, 14, out c, 4);
            if (c != 2) return true;
            uint pid; GetWindowThreadProcessId(h, out pid);
            r.Add(h.ToInt64() + "|" + pid + "|" + sb);
            return true;
        }, IntPtr.Zero);
        return r;
    }

    public static string Show(long hwnd) {
        var shell = (IServiceProvider10)Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("C2F03A33-21F5-47FA-B4BB-156362A2F239")));
        var g = typeof(IApplicationViewCollection).GUID;
        var views = (IApplicationViewCollection)shell.QueryService(ref g, ref g);
        IApplicationView view;
        int hr = views.GetViewForHwnd(new IntPtr(hwnd), out view);
        if (hr != 0 || view == null) return "sin vista (0x" + hr.ToString("X") + ")";
        hr = view.SetCloak(1, 0);
        int c = 0; DwmGetWindowAttribute(new IntPtr(hwnd), 14, out c, 4);
        return "SetCloak=0x" + hr.ToString("X") + " cloaked ahora=" + c;
    }
}
'@

# Excluir las ventanas que GlazeWM gestiona: esas están ocultas a propósito
# porque están en otro workspace (Alt+número las muestra).
$managed = @()
$cli = "C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe"
if (Get-Process glazewm -ErrorAction SilentlyContinue) {
    $managed = @(((& $cli query windows) | ConvertFrom-Json).data.windows | ForEach-Object { [int64]$_.handle })
}

$lost = [Uncloak]::Lost() | Where-Object { $managed -notcontains [int64](($_ -split '\|')[0]) }
if (-not $lost) { "No hay ventanas perdidas."; return }
# Apps de sistema que Windows mantiene ocultas siempre (no son ventanas perdidas)
$system = 'ApplicationFrameHost', 'SystemSettings', 'TextInputHost', 'ShellExperienceHost', 'SearchHost', 'StartMenuExperienceHost'
foreach ($l in $lost) {
    $h, $procId, $title = $l -split '\|', 3
    $proc = (Get-Process -Id $procId -ErrorAction SilentlyContinue).Name
    if ($system -contains $proc) { continue }
    $line = "{0,-10} {1}" -f $proc, $title
    if ($Match -and ($line -notmatch $Match)) { continue }
    if ($List) { $line; continue }
    "$line  ->  " + [Uncloak]::Show([int64]$h)
}

# ============================================================
# Puente rápido AutoHotkey -> GlazeWM
# ============================================================
# Mantiene UNA conexión WebSocket abierta con GlazeWM (ws://localhost:6123)
# y escucha en la named pipe \\.\pipe\win2hyprland-ws.
# AutoHotkey escribe el nombre del workspace ("3") en la pipe (~1 ms) y
# este proceso manda "command focus --workspace 3" por el WebSocket ya abierto.
#
# Por qué: lanzar glazewm.exe por cada Alt+número costaba ~270 ms;
# por el WebSocket abierto son ~50-90 ms (lo que tarda GlazeWM en sí).
#
# Coalescencia: si llegan varias pulsaciones mientras GlazeWM procesa una,
# solo se manda la última (así Alt+1234 4321 rápido no se bugea).
#
# Lo arranca ahk/hotkeys.ahk oculto. Solo puede haber una instancia (mutex).
# ============================================================

Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.IO.Pipes;
using System.Net.WebSockets;
using System.Text;
using System.Threading;

public static class GlazeBridge {
    static string target = null;   // último workspace pedido
    static string sent = null;     // último workspace enviado
    static readonly object gate = new object();
    static readonly AutoResetEvent wake = new AutoResetEvent(false);
    static readonly bool Verbose = Environment.GetEnvironmentVariable("GLAZE_BRIDGE_VERBOSE") == "1";
    static readonly string logPath = Path.Combine(Path.GetTempPath(), "glaze-bridge.log");

    static void Log(string s) {
        try { File.AppendAllText(logPath, DateTime.Now.ToString("HH:mm:ss.fff") + " " + s + Environment.NewLine); } catch {}
    }

    // Campo estático: si fuera una variable local, el recolector de basura podría
    // liberarla y soltar el mutex, permitiendo un segundo puente.
    static Mutex instanceMutex;

    public static bool AcquireSingleInstance() {
        bool created;
        instanceMutex = new Mutex(true, "Win2Hyprland.GlazeBridge", out created);
        return created;
    }

    public static void Run() {

        var sender = new Thread(SendLoop) { IsBackground = true };
        sender.Start();

        // Cada cliente (AutoHotkey mantiene una conexión abierta) se atiende en su
        // propio hilo, y enseguida se crea otra instancia de la pipe para el siguiente.
        while (true) {
            NamedPipeServerStream pipe = null;
            try {
                pipe = new NamedPipeServerStream("win2hyprland-ws", PipeDirection.In,
                           NamedPipeServerStream.MaxAllowedServerInstances, PipeTransmissionMode.Byte);
                pipe.WaitForConnection();
                var p = pipe;
                new Thread(() => ReadClient(p)) { IsBackground = true }.Start();
            } catch (Exception ex) {
                Log("pipe: " + ex.Message);
                if (pipe != null) pipe.Dispose();
                Thread.Sleep(50);
            }
        }
    }

    static void ReadClient(NamedPipeServerStream pipe) {
        try {
            using (pipe)
            using (var r = new StreamReader(pipe, Encoding.UTF8)) {
                string line;
                while ((line = r.ReadLine()) != null) {
                    line = line.Trim();
                    if (line.Length == 0) continue;
                    lock (gate) target = line;
                    if (Verbose) Log("recibido " + line);
                    wake.Set();
                }
            }
        } catch (Exception ex) { Log("cliente: " + ex.Message); }
    }

    static ClientWebSocket ws = null;
    static readonly byte[] buf = new byte[1 << 20];

    // Manda "command focus --workspace t" y espera la respuesta. false si falló.
    static bool SendFocus(string t) {
        try {
            if (ws == null || ws.State != WebSocketState.Open) {
                if (ws != null) ws.Dispose();
                ws = new ClientWebSocket();
                // 127.0.0.1 y no "localhost": localhost prueba IPv6 primero y tarda ~2 s
                ws.ConnectAsync(new Uri("ws://127.0.0.1:6123"), CancellationToken.None).Wait(2000);
                if (ws.State != WebSocketState.Open) throw new Exception("sin conexion");
            }
            var msg = Encoding.UTF8.GetBytes("command focus --workspace " + t);
            ws.SendAsync(new ArraySegment<byte>(msg), WebSocketMessageType.Text, true, CancellationToken.None).Wait();
            var cts = new CancellationTokenSource(3000);
            while (true) {
                var sb = new StringBuilder();
                WebSocketReceiveResult res;
                do {
                    res = ws.ReceiveAsync(new ArraySegment<byte>(buf), cts.Token).Result;
                    sb.Append(Encoding.UTF8.GetString(buf, 0, res.Count));
                } while (!res.EndOfMessage);
                if (sb.ToString().Contains("\"client_response\"")) return true;
            }
        } catch (Exception ex) {
            Log("envio: " + ex.Message);
            if (ws != null) { try { ws.Abort(); } catch {} ws.Dispose(); ws = null; }
            Thread.Sleep(300); // GlazeWM reiniciándose: reintentar
            return false;
        }
    }

    // Manda todo lo pendiente, siempre solo el último workspace pedido.
    static void Drain() {
        while (true) {
            string t;
            lock (gate) { t = target; if (t == null || t == sent) return; }
            if (SendFocus(t)) {
                lock (gate) sent = t;
                if (Verbose) Log("enviado " + t);
            }
        }
    }

    static void SendLoop() {
        bool skipWait = false;
        while (true) {
            if (!skipWait) wake.WaitOne(500);
            skipWait = false;
            Drain();

            string last;
            lock (gate) last = sent;
            if (last == null) continue;

            // Asentar: tras una ráfaga GlazeWM a veces "vuelve" a un workspace
            // anterior al procesar tarde el foco de una de sus ventanas.
            // Cuando dejan de llegar teclas, se re-manda el último workspace
            // (si ya está activo, GlazeWM no hace nada: sin parpadeo).
            foreach (int delay in new[] { 90, 220 }) {
                if (wake.WaitOne(delay)) { skipWait = true; break; } // llegó otra tecla
                SendFocus(last);
                if (Verbose) Log("asentar " + last);
            }
            if (skipWait) continue;

            // Olvidar el último enviado: así un cambio hecho por otro medio
            // (clic en la barra, Alt+Shift+N) no hace que se ignore la próxima tecla.
            lock (gate) { if (target == sent) { target = null; sent = null; } }
        }
    }

    // ========================================================
    // Autotiling estilo dwindle de Hyprland
    // ========================================================
    // Al enfocar una ventana en mosaico: si es más ancha que alta, la siguiente
    // ventana se abrirá a su lado (horizontal); si es más alta, debajo (vertical).
    // Con 3 ventanas: una a la izquierda completa y dos apiladas a la derecha.
    // Va por su propia conexión WebSocket; espera 50 ms de calma y no actúa
    // mientras haya un cambio de workspace en curso (para no frenar Alt+número).
    static ClientWebSocket ev = null;
    static readonly object evSend = new object();
    static readonly AutoResetEvent tileWake = new AutoResetEvent(false);
    static string pendWin = null, pendDir = null, appliedWin = null, appliedDir = null;
    static DateTime pendAt = DateTime.MinValue;

    public static void StartAutoTiling() {
        new Thread(AutoTileReader) { IsBackground = true }.Start();
        new Thread(AutoTileWorker) { IsBackground = true }.Start();
    }

    static void EvSend(string text) {
        var m = Encoding.UTF8.GetBytes(text);
        lock (evSend) ev.SendAsync(new ArraySegment<byte>(m), WebSocketMessageType.Text, true, CancellationToken.None).Wait();
    }

    static void AutoTileReader() {
        var rbuf = new byte[1 << 16];
        var json = new System.Web.Script.Serialization.JavaScriptSerializer { MaxJsonLength = int.MaxValue, RecursionLimit = 2000 };
        while (true) {
            try {
                ev = new ClientWebSocket();
                ev.ConnectAsync(new Uri("ws://127.0.0.1:6123"), CancellationToken.None).Wait(2000);
                if (ev.State != WebSocketState.Open) throw new Exception("sin conexion");
                EvSend("sub -e focus_changed");
                while (ev.State == WebSocketState.Open) {
                    var sb = new StringBuilder();
                    WebSocketReceiveResult res;
                    do {
                        res = ev.ReceiveAsync(new ArraySegment<byte>(rbuf), CancellationToken.None).Result;
                        sb.Append(Encoding.UTF8.GetString(rbuf, 0, res.Count));
                    } while (!res.EndOfMessage);
                    if (res.MessageType == WebSocketMessageType.Close) break;
                    var s = sb.ToString();
                    if (!s.Contains("\"focus_changed\"")) continue;
                    var msg = json.Deserialize<System.Collections.Generic.Dictionary<string, object>>(s);
                    var data = msg["data"] as System.Collections.Generic.Dictionary<string, object>;
                    if (data == null || !data.ContainsKey("focusedContainer")) continue;
                    var fc = data["focusedContainer"] as System.Collections.Generic.Dictionary<string, object>;
                    if (fc == null || (fc["type"] as string) != "window") continue;
                    var st = fc["state"] as System.Collections.Generic.Dictionary<string, object>;
                    if (st == null || (st["type"] as string) != "tiling") continue;
                    double w = Convert.ToDouble(fc["width"]), h = Convert.ToDouble(fc["height"]);
                    lock (gate) {
                        pendWin = fc["id"] as string;
                        pendDir = w >= h ? "horizontal" : "vertical";
                        pendAt = DateTime.UtcNow;
                    }
                    tileWake.Set();
                }
            } catch (Exception ex) { Log("autotiling: " + ex.Message); }
            try { if (ev != null) ev.Abort(); } catch {}
            Thread.Sleep(1000); // GlazeWM reiniciándose: reconectar
        }
    }

    static void AutoTileWorker() {
        while (true) {
            tileWake.WaitOne();
            while (true) {
                string win, dir; DateTime at; bool switching;
                lock (gate) { win = pendWin; dir = pendDir; at = pendAt; switching = target != null; }
                if (win == null) break;
                var wait = 50 - (DateTime.UtcNow - at).TotalMilliseconds;
                if (wait > 0 || switching) { Thread.Sleep(wait > 0 ? (int)wait + 1 : 60); continue; }
                lock (gate) { if (pendAt != at) continue; pendWin = null; }
                if (win == appliedWin && dir == appliedDir) break;
                try {
                    EvSend("command set-tiling-direction " + dir);
                    appliedWin = win; appliedDir = dir;
                    if (Verbose) Log("autotiling " + dir);
                } catch (Exception ex) { Log("autotiling envio: " + ex.Message); }
                break;
            }
        }
    }
}
'@ -ReferencedAssemblies System.Web.Extensions

if (-not [GlazeBridge]::AcquireSingleInstance()) { exit }  # ya hay otro puente corriendo
[GlazeBridge]::StartAutoTiling()
[GlazeBridge]::Run()

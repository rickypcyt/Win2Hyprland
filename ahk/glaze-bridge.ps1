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
                    if (line.StartsWith("swap ")) {          // Win+flechas
                        var dir = line.Substring(5);
                        new Thread(() => Swap(dir)) { IsBackground = true }.Start();
                        continue;
                    }
                    lock (gate) target = line;               // Alt+número
                    if (Verbose) Log("recibido " + line);
                    wake.Set();
                }
            }
        } catch (Exception ex) { Log("cliente: " + ex.Message); }
    }

    // ========================================================
    // Win+flechas = swapwindow de Hyprland
    // ========================================================
    // GlazeWM no tiene "swap"; su "move" reorganiza el árbol y, si no hay
    // ventana en esa dirección, crea filas/columnas a todo lo ancho.
    // Aquí: si la ventana enfocada tiene en esa dirección una ventana hermana
    // (mismo grupo, mismo eje), "move" las intercambia. Si no, no se hace nada.
    static readonly object swapLock = new object();

    static string Request(ClientWebSocket c, string text) {
        var m = Encoding.UTF8.GetBytes(text);
        c.SendAsync(new ArraySegment<byte>(m), WebSocketMessageType.Text, true, CancellationToken.None).Wait();
        var rb = new byte[1 << 16];
        var cts = new CancellationTokenSource(3000);
        while (true) {
            var sb = new StringBuilder();
            WebSocketReceiveResult res;
            do {
                res = c.ReceiveAsync(new ArraySegment<byte>(rb), cts.Token).Result;
                sb.Append(Encoding.UTF8.GetString(rb, 0, res.Count));
            } while (!res.EndOfMessage);
            var s = sb.ToString();
            if (s.Contains("\"client_response\"")) return s;
        }
    }

    // Camino desde el workspace hasta la ventana con foco (último = la ventana).
    static bool FindFocusedPath(System.Collections.Generic.Dictionary<string, object> node,
                                System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>> path) {
        path.Add(node);
        if ((node["type"] as string) == "window")
            return node.ContainsKey("hasFocus") && (bool)node["hasFocus"] || Pop(path);
        var kids = node.ContainsKey("children") ? node["children"] as System.Collections.ArrayList : null;
        if (kids != null)
            foreach (var k in kids) {
                var kd = k as System.Collections.Generic.Dictionary<string, object>;
                if (kd != null && FindFocusedPath(kd, path)) return true;
            }
        return Pop(path);
    }
    static bool Pop(System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>> p) { p.RemoveAt(p.Count - 1); return false; }

    static System.Collections.ArrayList Kids(System.Collections.Generic.Dictionary<string, object> n) {
        return n.ContainsKey("children") ? n["children"] as System.Collections.ArrayList : null;
    }
    // Un "envoltorio" es un split con un solo hijo (lo crea set-tiling-direction del autotiling).
    static bool IsWrapper(System.Collections.Generic.Dictionary<string, object> n) {
        var k = Kids(n);
        return (n["type"] as string) == "split" && k != null && k.Count == 1;
    }

    static void CollectTiledWindows(System.Collections.Generic.Dictionary<string, object> n,
                                    System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>> outList) {
        if ((n["type"] as string) == "window") {
            var st = n["state"] as System.Collections.Generic.Dictionary<string, object>;
            if (st != null && (st["type"] as string) == "tiling") outList.Add(n);
            return;
        }
        var k = Kids(n);
        if (k != null) foreach (var c in k) { var d = c as System.Collections.Generic.Dictionary<string, object>; if (d != null) CollectTiledWindows(d, outList); }
    }

    static double D(System.Collections.Generic.Dictionary<string, object> n, string k) { return Convert.ToDouble(n[k]); }

    // ¿Hay otra ventana en mosaico al otro lado de ese borde, solapando en el eje perpendicular?
    static bool HasWindowInDirection(System.Collections.Generic.Dictionary<string, object> w,
                                     System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>> all, string dir) {
        double x = D(w, "x"), y = D(w, "y"), r = x + D(w, "width"), b = y + D(w, "height");
        foreach (var o in all) {
            if (ReferenceEquals(o, w)) continue;
            double ox = D(o, "x"), oy = D(o, "y"), or_ = ox + D(o, "width"), ob = oy + D(o, "height");
            bool overlapY = oy < b - 2 && ob > y + 2, overlapX = ox < r - 2 && or_ > x + 2;
            if (dir == "left"  && or_ <= x + 2 && overlapY) return true;
            if (dir == "right" && ox >= r - 2  && overlapY) return true;
            if (dir == "up"    && ob <= y + 2  && overlapX) return true;
            if (dir == "down"  && oy >= b - 2  && overlapX) return true;
        }
        return false;
    }

    static volatile bool swapping = false;   // pausa el autotiling durante un intercambio
    static string Opposite(string d) { return d == "left" ? "right" : d == "right" ? "left" : d == "up" ? "down" : "up"; }

    // Busca una ventana por id en el workspace con foco y devuelve su camino.
    static System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>> PathOf(ClientWebSocket c, string id) {
        var json = new System.Web.Script.Serialization.JavaScriptSerializer { MaxJsonLength = int.MaxValue, RecursionLimit = 2000 };
        var resp = json.Deserialize<System.Collections.Generic.Dictionary<string, object>>(Request(c, "query workspaces"));
        var wss = (resp["data"] as System.Collections.Generic.Dictionary<string, object>)["workspaces"] as System.Collections.ArrayList;
        foreach (var w in wss) {
            var p = new System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>>();
            if (FindById(w as System.Collections.Generic.Dictionary<string, object>, id, p)) return p;
        }
        return null;
    }
    static bool FindById(System.Collections.Generic.Dictionary<string, object> n, string id,
                         System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>> p) {
        p.Add(n);
        if ((n["id"] as string) == id) return true;
        var k = Kids(n);
        if (k != null) foreach (var c in k) if (FindById(c as System.Collections.Generic.Dictionary<string, object>, id, p)) return true;
        p.RemoveAt(p.Count - 1); return false;
    }

    // A está sola en su columna; group es el grupo de al lado. Intercambia A con la
    // ventana T del grupo más cercana a A en el eje perpendicular.
    static void SwapAcrossGroups(ClientWebSocket c, System.Collections.Generic.Dictionary<string, object> a,
                                 System.Collections.Generic.Dictionary<string, object> group, string dir) {
        var inGroup = new System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>>();
        CollectTiledWindows(group, inGroup);
        if (inGroup.Count == 0) return;
        bool horiz = dir == "left" || dir == "right";
        double ac = horiz ? D(a, "y") + D(a, "height") / 2 : D(a, "x") + D(a, "width") / 2;
        System.Collections.Generic.Dictionary<string, object> t = null; double best = double.MaxValue;
        foreach (var w in inGroup) {
            // más cercana: primero la más pegada al borde que compartimos, luego la más alineada
            double edge = dir == "right" ? D(w, "x") : dir == "left" ? -(D(w, "x") + D(w, "width"))
                        : dir == "down" ? D(w, "y") : -(D(w, "y") + D(w, "height"));
            double wc = horiz ? D(w, "y") + D(w, "height") / 2 : D(w, "x") + D(w, "width") / 2;
            double score = edge * 10000 + Math.Abs(wc - ac);
            if (score < best) { best = score; t = w; }
        }
        string aId = a["id"] as string, tId = t["id"] as string;
        string groupDir = group["tilingDirection"] as string;
        swapping = true;
        try {
            // 1. T sale de su grupo hacia A:  [A | T | resto]
            Request(c, "command focus --container-id " + tId);
            Request(c, "command move --direction " + Opposite(dir));
            // 2. A y T son vecinas: intercambiarlas:  [T | A | resto]
            Request(c, "command focus --container-id " + aId);
            Request(c, "command move --direction " + dir);
            // 3. Meter A en el resto del grupo, en el sitio que dejó T.
            var pa = PathOf(c, aId);
            if (pa != null && pa.Count >= 2) {
                var p2 = pa[pa.Count - 2]; var k2 = Kids(p2);
                int j = k2.IndexOf(pa[pa.Count - 1]) + ((dir == "left" || dir == "up") ? -1 : 1);
                var rest = (j >= 0 && j < k2.Count) ? k2[j] as System.Collections.Generic.Dictionary<string, object> : null;
                while (rest != null && IsWrapper(rest)) rest = Kids(rest)[0] as System.Collections.Generic.Dictionary<string, object>;
                if (rest != null && (rest["type"] as string) == "window") {
                    // El resto quedó en una sola ventana C: apilar A y C como estaba el grupo.
                    Request(c, "command set-tiling-direction " + groupDir);
                    Request(c, "command focus --container-id " + (rest["id"] as string));
                    Request(c, "command move --direction " + Opposite(dir));
                } else if (rest != null) {
                    Request(c, "command move --direction " + dir);
                }
            }
            Request(c, "command focus --container-id " + aId);
            if (Verbose) Log("swap " + dir + ": intercambio entre grupos");
        } finally { swapping = false; }
    }

    static void Swap(string dir) {
        lock (swapLock) {
            ClientWebSocket c = null;
            try {
                c = new ClientWebSocket();
                c.ConnectAsync(new Uri("ws://127.0.0.1:6123"), CancellationToken.None).Wait(2000);
                if (c.State != WebSocketState.Open) throw new Exception("sin conexion");
                var json = new System.Web.Script.Serialization.JavaScriptSerializer { MaxJsonLength = int.MaxValue, RecursionLimit = 2000 };
                var resp = json.Deserialize<System.Collections.Generic.Dictionary<string, object>>(Request(c, "query workspaces"));
                var wss = (resp["data"] as System.Collections.Generic.Dictionary<string, object>)["workspaces"] as System.Collections.ArrayList;
                var path = new System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>>();
                bool found = false;
                foreach (var w in wss) {
                    var wsd = w as System.Collections.Generic.Dictionary<string, object>;
                    if (wsd != null && wsd.ContainsKey("hasFocus") && (bool)wsd["hasFocus"]) { found = FindFocusedPath(wsd, path); break; }
                }
                if (!found || path.Count < 2) { if (Verbose) Log("swap " + dir + ": sin ventana con foco"); return; }
                var win = path[path.Count - 1];
                var st = win["state"] as System.Collections.Generic.Dictionary<string, object>;
                if (st == null || (st["type"] as string) != "tiling") return;   // flotante / fullscreen: nada
                string axis = (dir == "left" || dir == "right") ? "horizontal" : "vertical";
                int delta = (dir == "left" || dir == "up") ? -1 : 1;
                // Subir solo a través de envoltorios de un hijo hasta el grupo real.
                int i = path.Count - 1;
                while (i - 1 >= 1 && IsWrapper(path[i - 1])) i--;
                var cur = path[i]; var par = path[i - 1];
                System.Collections.Generic.Dictionary<string, object> sib = null, sameAxisSibling = null;
                if ((par["tilingDirection"] as string) == axis) {
                    var kids = Kids(par);
                    int j = kids.IndexOf(cur) + delta;
                    if (j >= 0 && j < kids.Count) {
                        sib = kids[j] as System.Collections.Generic.Dictionary<string, object>;
                        while (sib != null && IsWrapper(sib)) sib = Kids(sib)[0] as System.Collections.Generic.Dictionary<string, object>;
                        sameAxisSibling = sib;
                    }
                }
                bool sibIsTiledWindow = sib != null && (sib["type"] as string) == "window"
                    && ((sib["state"] as System.Collections.Generic.Dictionary<string, object>)["type"] as string) == "tiling";
                if (sibIsTiledWindow) {
                    Request(c, "command move --direction " + dir);
                    if (Verbose) Log("swap " + dir + ": intercambiadas");
                    return;
                }
                // Sin vecina en el mismo grupo: si hay alguna ventana en mosaico en esa
                // dirección (otra columna/fila), mover allí con el move de GlazeWM
                // (movewindow de Hyprland). Si no hay ninguna, no hacer nada: así
                // nunca se crean filas/columnas a todo lo ancho.
                var all = new System.Collections.Generic.List<System.Collections.Generic.Dictionary<string, object>>();
                CollectTiledWindows(path[0], all);
                if (!HasWindowInDirection(win, all, dir)) { if (Verbose) Log("swap " + dir + ": no hay ventana en esa dirección, nada"); return; }

                // Caso especial: la ventana está sola en su columna y al lado hay un grupo.
                // Con move, la columna desaparecería y GlazeWM lo convertiría todo en
                // filas. En su lugar: intercambio real con la ventana más cercana del grupo.
                var parKids = Kids(par);
                var rawSib = (sameAxisSibling != null) ? sameAxisSibling : null;
                if ((par["tilingDirection"] as string) == axis && parKids.Count == 2 && rawSib != null
                    && (rawSib["type"] as string) != "window") {
                    SwapAcrossGroups(c, win, rawSib, dir);
                    return;
                }
                Request(c, "command move --direction " + dir);
                if (Verbose) Log("swap " + dir + ": movida a otro grupo");
            } catch (Exception ex) { Log("swap: " + ex.Message); }
            finally { try { if (c != null) c.Abort(); } catch {} }
        }
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
                lock (gate) { win = pendWin; dir = pendDir; at = pendAt; switching = target != null || swapping; }
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

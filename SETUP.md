# CS2 Web Radar Setup Guide

> Current architecture: **Aimware Lua → UDP → Node.js Server → WebSocket → Browser Radar**

## Quick Setup (5 minutes)

### Step 1 — Start the server

Double-click `ServerLauncher.bat`, or run from PowerShell:

```powershell
cd "c:\Users\joeis\OneDrive\桌面\Aimware Lua\web_radar"
node server.js
```

On startup you should see:

```
[Radar] UDP listening on 0.0.0.0:12345
[Radar] WebSocket server running on ws://0.0.0.0:8765
[Radar] HTTP server running on http://0.0.0.0:8080
```

- HTTP port `8080` — radar web UI
- WebSocket port `8765` — real-time push
- UDP port `12345` — receives Lua data

---

### Step 2 — Open the radar page

Open Chrome / Edge and visit:

```
http://localhost:8080
```

> Static demo (no server required): https://mingyiu.github.io/WebRader/

You should see the radar interface with a map background and live player dots.

---

### Step 3 — Load the Lua script into Aimware

1. Launch CS2 and join any server
2. Open Aimware's Lua editor
3. Load `aimware_client.lua` (no `test_loader.lua` needed)

```lua
-- Aimware console
lua_load aimware_client.lua
```

> After editing the script, use `lua_reload()` to hot-reload — no need to restart CS2.

---

### Step 4 — Verify

Join a CS2 match and you should see on the radar:

- **You**: green dot + name
- **Teammates**: blue dots + name (light blue text)
- **Enemies**: red dots + name (light red text)
- **Dead players**: hidden from the map, still listed in the side panels with a 💀 marker

A console message like `[Radar] Sent #N: X players` confirms the Lua client is pushing data.

---

## Reloading After Edits

| Component | Command |
|-----------|---------|
| Aimware Lua | `lua_reload()` |
| Radar page  | `Ctrl + F5` (hard refresh) |
| Node.js server | `Ctrl + C` to stop, then `node server.js` |

---

## Troubleshooting

### Q: Server fails with "node is not recognized"
**A:** Node.js is not installed. Get the LTS build from https://nodejs.org/, then reopen the terminal.

### Q: First `npm install` is very slow or fails
**A:** Switch to a faster mirror:
```powershell
npm config set registry https://registry.npmmirror.com
```
Then delete `node_modules` and re-run `npm install`.

### Q: Browser shows "Cannot connect"
**A:**
- Make sure the server terminal is still running.
- Check that ports 8080 / 8765 are not in use by another process.
- Open browser DevTools (F12) and inspect the Console for errors.

### Q: Radar shows the map but no players
**A:**
- Make sure `aimware_client.lua` is loaded. Run `lua_reload()` and check for errors.
- You must be in an active match (lobby does not push data).
- The console should continuously log `[Radar] Sent #N: X players`.
- If `X = 0`, Aimware cannot find any `C_CSPlayerPawn`. Try a newer Aimware version.

### Q: Lua script errors with "attempt to call a nil value"
**A:** Your Aimware version is too old. The current `aimware_client.lua` requires Aimware V6 or V7.

---

## Ports

| Port | Protocol | Direction | Configurable in |
|------|----------|-----------|----------------|
| 8080 | HTTP | Server → Browser | `server.js` |
| 8765 | WebSocket | Server → Browser | `server.js` |
| 12345 | UDP | Lua → Server | `server.js` + `aimware_client.lua` (`CONFIG`) |

Change the target port by editing the `CONFIG` block at the top of `aimware_client.lua`:

```lua
local CONFIG = {
    update_interval = 0.033,  -- seconds (~30 FPS)
    server_ip = "127.0.0.1",
    server_port = 12345,
}
```

---

## File Reference

| File | Purpose | Required? |
|------|---------|-----------|
| `server.js` | Node.js relay (UDP in + WebSocket out + HTTP static) | ✅ |
| `radar.html` | Main radar page | ✅ |
| `index.html` | GitHub Pages entry (redirects to `radar.html`) | ✅ |
| `coordinate_tool.html` | Coordinate calibration tool | ✅ |
| `map_configs.js` | Map coordinate config (pos_x / pos_y / scale / rotate) | ✅ |
| `image/{map}.png` | Map images | ✅ |
| `aimware_client.lua` | Aimware Lua client script | ✅ (local use) |
| `ServerLauncher.bat` | Windows one-click launcher | Recommended |
| `aimware_check.txt` | Aimware API probe output | Diagnostic |
| `probe*.lua` | Aimware API probe scripts | Diagnostic |

---

## Architecture

```
┌─────────────┐    UDP 12345      ┌──────────────────┐    WebSocket 8765    ┌─────────────┐
│   CS2       │ ────────────────→ │ Node.js          │ ───────────────────→ │  Browser    │
│ + Aimware   │                   │ server.js        │                      │ radar.html  │
│ aimware_    │                   │                  │ ←─── HTTP 8080 ───── │             │
│ client.lua  │                   │ (UDP/WS/HTTP)    │    (static files +   │             │
└─────────────┘                   └──────────────────┘     polling fallback) └─────────────┘
```

- **Latency**: ~1–5 ms (WebSocket real-time)
- **Update rate**: ~30 FPS
- **Fallback**: if the WebSocket fails to connect, the browser switches to HTTP polling automatically.

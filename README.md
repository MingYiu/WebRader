# CS2 Web Radar

Real-time CS2 radar running in the browser, powered by WebSocket for instant data delivery.

## Quick Start

### 1. Install dependencies

```bash
npm install
```

### 2. Start the server

```bash
# Windows
ServerLauncher.bat

# Or manually
node server.js
```

### 3. Load the Lua script in Aimware

Load `aimware_client.lua` in Aimware V6/V7.

### 4. Open the radar page

- **Local**: http://localhost:8080
- **Online demo (GitHub Pages)**: https://mingyiu.github.io/WebRader/

## GitHub Pages Deployment

The repository uses the `web_radar/` subdirectory as the Pages source.

- `index.html` — Auto-redirects to `radar.html` (default GitHub Pages entry)
- `radar.html` — Main radar page
- `coordinate_tool.html` — Coordinate calibration tool
- `map_configs.js` — Map coordinate configuration
- `server.js` — Node.js relay server (local use only, not deployed to Pages)
- `aimware_client.lua` — Aimware Lua client script (local use only, not deployed to Pages)

**Files served by Pages**: `index.html`, `radar.html`, `coordinate_tool.html`, `map_configs.js`, `image/` (map assets). The rest stays in the repo without being served by Pages; clone the repo and run `npm install` to use the relay server locally.

## Architecture

```
[Aimware Lua] --UDP--> [Node.js Server] --WebSocket--> [Browser Radar]
                 |
                 +--HTTP--> [Browser (Polling Fallback)]
```

- **Latency**: ~1–5 ms (WebSocket)
- **Update rate**: ~30 FPS
- **Protocols**: UDP (Lua → Server) + WebSocket (Server → Browser)

## File Reference

| File | Description |
|------|-------------|
| `server.js` | Node.js server (UDP receiver + WebSocket broadcaster + HTTP static) |
| `aimware_client.lua` | Aimware Lua client script |
| `radar.html` | Radar web UI |
| `index.html` | GitHub Pages entry (redirects to `radar.html`) |
| `coordinate_tool.html` | Coordinate calibration tool |
| `map_configs.js` | Map coordinate configuration |
| `ServerLauncher.bat` | Windows one-click launcher |

## Configuration

Edit the `CONFIG` block at the top of `aimware_client.lua`:

```lua
local CONFIG = {
    update_interval = 0.033,  -- update interval in seconds
    server_ip = "127.0.0.1",
    server_port = 12345,      -- UDP port
}
```

## Features

- Real-time player positions with name labels above each dot
- Team color coding (CT / T)
- Health and weapon info
- Round timer
- Scoreboard
- Bomb status
- Multi-map support (Dust2, Mirage, Inferno, etc.)
- Dead players hidden from the map view, still listed in the side panels
- WebSocket primary, HTTP polling fallback

## Map Images

Drop CS2 map screenshots into the `image/` folder, named `{map_name}.png`.

Use `coordinate_tool.html` to measure map coordinates and update `map_configs.js`.

## Ports

| Port | Protocol | Direction | Configurable in |
|------|----------|-----------|----------------|
| 8080 | HTTP | Server → Browser | `server.js` |
| 8765 | WebSocket | Server → Browser | `server.js` |
| 12345 | UDP | Lua → Server | `server.js` + `aimware_client.lua` (`CONFIG`) |

## License

MIT

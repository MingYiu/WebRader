# CS2 Web Radar

基于 Web 的实时 CS2 雷达，使用 WebSocket 进行即时数据传输。

## 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 启动服务器

```bash
# Windows
启动服务器.bat

# 或者手动运行
node server.js
```

### 3. 在 Aimware 中加载 Lua 脚本

加载 `aimware_client.lua` 到 Aimware V6/V7。

### 4. 打开雷达页面

本地：浏览器访问: http://localhost:8080

线上 (GitHub Pages)：浏览 https://mingyiu.github.io/WebRader/

## GitHub Pages 部署

仓库使用 `web_radar/` 子目录作为 Pages source。

- `index.html` —— 自动跳转到 `radar.html`(GitHub Pages 默认入口)
- `radar.html` —— 雷达主页
- `coordinate_tool.html` —— 坐标调试工具
- `map_configs.js` —— 地图坐标配置
- `server.js` —— Node.js 中转服务器(本地用,不需要部署到 Pages)
- `aimware_client.lua` —— Aimware Lua 客户端脚本(本地用,不需要部署到 Pages)

Pages 部署的文件清单:`index.html`、`radar.html`、`coordinate_tool.html`、`map_configs.js`、`image/`(地图资源)。其它文件可保留在仓库不被 Pages 加载,需要时手动 clone 后 `npm install` 跑服务端。

## 技术架构

```
[Aimware Lua] --UDP--> [Node.js Server] --WebSocket--> [Browser Radar]
                 |
                 +--HTTP--> [Browser (Polling Fallback)]
```

- **延迟**: ~1-5ms (WebSocket)
- **更新频率**: ~30 FPS
- **协议**: UDP (Lua→Server) + WebSocket (Server→Browser)

## 文件说明

| 文件 | 说明 |
|------|------|
| `server.js` | Node.js 服务器 (UDP 接收 + WebSocket 广播) |
| `aimware_client.lua` | Aimware Lua 客户端脚本 |
| `radar.html` | 雷达网页界面 |
| `map_configs.js` | 地图坐标配置 |
| `coordinate_tool.html` | 坐标调试工具 |

## 配置

在 `aimware_client.lua` 中修改:

```lua
local CONFIG = {
    update_interval = 0.033,  -- 更新间隔 (秒)
    server_ip = "127.0.0.1",
    server_port = 12345,      -- UDP 端口
}
```

## 功能

- 实时玩家位置显示
- 队伍颜色区分 (CT/T)
- 血量和武器信息
- 回合计时器
- 比分显示
- 炸弹状态
- 多地图支持 (Dust2, Mirage, Inferno 等)

## 地图图片

将 CS2 地图截图放入 `image/` 文件夹，命名为 `{map_name}.png`

可使用 `coordinate_tool.html` 工具测量地图坐标。

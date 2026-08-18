# CS2 Web Radar 设置指南

> 当前架构：**Aimware Lua → UDP → Node.js Server → WebSocket → 浏览器雷达**

## 快速设置 (5分钟)

### 第一步：启动服务器

双击运行 `ServerLauncher.bat`，或手动 PowerShell 运行：

```powershell
cd "c:\Users\joeis\OneDrive\桌面\Aimware Lua\web_radar"
node server.js
```

启动后会看到：

```
[Radar] UDP listening on 0.0.0.0:12345
[Radar] WebSocket server running on ws://0.0.0.0:8765
[Radar] HTTP server running on http://0.0.0.0:8080
```

- HTTP 端口 `8080` —— 雷达网页
- WebSocket 端口 `8765` —— 实时推送
- UDP 端口 `12345` —— 接收 Lua 数据

---

### 第二步：打开雷达网页

浏览器 (Chrome / Edge) 访问：

```
http://localhost:8080
```

> GitHub Pages 公共 demo（不需本地服务器，但只展示静态界面）：
> https://mingyiu.github.io/WebRader/

应该看到圆形雷达界面（地图为底，实时显示玩家）。

---

### 第三步：加载 Lua 脚本到 Aimware

1. 启动 CS2 并进入服务器
2. 打开 Aimware 的 Lua 编辑器
3. 加载 `aimware_client.lua` 一个即可

```lua
-- Aimware 控制台
lua_load aimware_client.lua
```

> 修改脚本后用 `lua_reload()` 热重载，不需要重启 CS2。

---

### 第四步：测试

进入 CS2 任意对局，浏览器雷达应该实时显示：

- **你自己**：绿色圆点 + 名字
- **队友**：蓝色圆点 + 名字（淡蓝字）
- **敌人**：红色圆点 + 名字（淡红字）
- **死亡玩家**：灰色半透明

控制台看到 `[Radar] Sent #N: X players` 表示 Aimware 端正常推数据。

---

## 修改代码后重新加载

| 端 | 命令 |
|---|---|
| Aimware Lua | `lua_reload()` |
| 雷达网页 | `Ctrl + F5` 强刷 |
| Node.js 服务器 | `Ctrl + C` 停掉再 `node server.js` |

---

## 常见问题

### Q: 服务器启动报 "node 不是内部或外部命令"
**A:** 没装 Node.js，去 https://nodejs.org/ 装 LTS 版。装完后重开终端。

### Q: 第一次运行 npm install 很慢 / 失败
**A:** 切到国内镜像：
```powershell
npm config set registry https://registry.npmmirror.com
```
然后删除 `node_modules` 重新跑 `npm install`。

### Q: 浏览器显示 "Cannot connect"
**A:**
- 确认服务器已启动（终端还活着）
- 检查端口 8080 / 8765 是否被占用
- 浏览器 F12 看 Console 错误

### Q: 雷达有画面但没玩家
**A:**
- 确认 `aimware_client.lua` 已加载（控制台输入 `lua_reload()` 看是否有错误）
- 必须在游戏对局里（大厅不会推数据）
- 控制台应持续输出 `[Radar] Sent #N: X players`
- 如果 `X = 0`，Aimbot 没找到任何 `C_CSPlayerPawn` —— 升级 Aimware 版本

### Q: Lua 脚本报 `attempt to call a nil value`
**A:** Aimware 版本太旧不支持该 API。当前 `aimware_client.lua` 需要 Aimware V6/V7。

---

## 端口说明

| 端口 | 协议 | 方向 | 配置位置 |
|---|---|---|---|
| 8080 | HTTP | Server → Browser | `server.js` |
| 8765 | WebSocket | Server → Browser | `server.js` |
| 12345 | UDP | Lua → Server | `server.js` + `aimware_client.lua` 的 `CONFIG` |

修改 `aimware_client.lua` 顶部的 `CONFIG` 块可改目标端口：

```lua
local CONFIG = {
    update_interval = 0.033,  -- 秒 (~30 FPS)
    server_ip = "127.0.0.1",
    server_port = 12345,
}
```

---

## 项目文件说明

| 文件 | 作用 | 必需? |
|---|---|---|
| `server.js` | Node.js 中转（UDP 收 + WebSocket 发 + HTTP 静态） | ✅ |
| `radar.html` | 雷达主页面 | ✅ |
| `index.html` | GitHub Pages 入口（重定向到 `radar.html`） | ✅ |
| `coordinate_tool.html` | 坐标调试工具 | ✅ |
| `map_configs.js` | 地图坐标配置（pos_x/pos_y/scale/rotate） | ✅ |
| `image/{map}.png` | 地图图片资源 | ✅ |
| `aimware_client.lua` | Aimware 客户端 Lua 脚本 | ✅（本地用） |
| `ServerLauncher.bat` | Windows 一键启动服务器 | 推荐 |
| `aimware_check.txt` | Aimware API 探测输出（排查用） | 排查用 |
| `probe*.lua` | Aimware API 探测脚本（排查用） | 排查用 |

---

## 架构图

```
┌─────────────�    UDP 12345      ┌──────────────────┐    WebSocket 8765    ┌─────────────┐
│   CS2       │ ────────────────→ │ Node.js          │ ───────────────────→ │  Browser    │
│ + Aimware   │                   │ server.js        │                      │ radar.html  │
│ aimware_    │                   │                  │ ←─── HTTP 8080 ───── │             │
│ client.lua  │                   │ (UDP/WS/HTTP)    │    (静态文件 +       │             │
└─────────────┘                   └──────────────────┘     polling fallback) └─────────────┘
```

- **延迟**：~1-5ms (WebSocket 实时)
- **更新频率**：~30 FPS
- **降级**：若 WS 连不上，浏览器会切到 HTTP polling（兜底）

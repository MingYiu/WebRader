# CS2 Web Radar 设置指南

## 快速设置 (5分钟)

### 第一步：启动服务器

双击运行 `启动服务器.bat`，或手动打开 PowerShell 运行：

```powershell
cd "c:\Users\joeis\OneDrive\桌面\Aimware Lua\web_radar"
python server.py
```

看到以下内容表示服务器启动成功：
```
Server running at http://localhost:8080
Press Ctrl+C to stop
```

### 第二步：打开雷达网页

打开浏览器（Chrome/Edge），访问：

```
http://localhost:8080
```

应该能看到一个圆形雷达界面（目前是空的）。

### 第三步：加载 Lua 脚本

1. **启动 CS2 和 Aimware**
2. **打开 Aimware Lua 编辑器**
   - 通常在 Aimware 菜单 → Lua Settings 或 Settings → Lua

3. **加载两个脚本**（按顺序）：

   a. 先加载 `test_loader.lua`
      - Aimware → Lua → Load → 选择 `test_loader.lua`
      
   b. 再加载 `aimware_client.lua`
      - Aimware → Lua → Load → 选择 `aimware_client.lua`
      - 或者在控制台输入：`lua_load()`

### 第四步：测试

进入 CS2 任意服务器，你应该能在浏览器雷达上看到：
- 你的位置（白色圆点）
- 其他玩家位置（蓝色=友军，红色=敌人）

---

## 如果需要重新加载脚本（修改代码后）

**方法一：使用控制台命令（推荐）**
1. 进入游戏
2. 按 `~` 打开控制台
3. 输入 `lua_reload()` 回车

**方法二：手动重新加载**
1. Aimware → Lua → Scripts
2. 找到 `aimware_client.lua`
3. 点击 Unload
4. 再点击 Load

---

## 常见问题

### Q: 服务器启动报错 "No module named 'http'"
**A:** Python 版本太旧，升级 Python 或使用：
```powershell
python3 server.py
```

### Q: 浏览器显示 "Cannot connect"
**A:** 
- 确认服务器已启动
- 检查端口是否被占用（默认 8080）
- 尝试刷新页面

### Q: Lua 脚本加载后崩溃
**A:** 
- 使用 `lua_unload()` 卸载
- 检查错误日志
- 修改代码后用 `lua_reload()` 重新加载

### Q: 雷达显示但没有玩家
**A:**
- 确认已加载 `aimware_client.lua`
- 检查是否在游戏服务器中（不是主菜单）
- 查看控制台是否有 `[Radar]` 输出

---

## 项目文件说明

| 文件 | 作用 |
|------|------|
| `server.py` | HTTP 服务器，读取游戏数据并发送给网页 |
| `radar.html` | 雷达网页界面，用浏览器打开 |
| `aimware_client.lua` | 游戏内脚本，读取玩家数据写入文件 |
| `test_loader.lua` | 测试辅助工具，用于热重载 |
| `radar_data.json` | 数据文件，游戏和服务器共享 |

---

## 架构图

```
┌─────────────┐     file.Write()      ┌─────────────────┐
│    CS2      │ ──────────────────────→│ radar_data.json │
│  + Aimware  │                       └────────┬────────┘
└─────────────┘                                │
                                               │ HTTP GET
                                               ▼
┌─────────────┐     HTTP (8080)      ┌─────────────────┐
│   浏览器    │←─────────────────────│   Python Server │
│ localhost   │                      │    server.py    │
└─────────────┘                      └─────────────────┘
```

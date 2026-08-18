-- ============================================
-- Lua 测试工具 - 测试辅助器
-- 始终保持加载，用于控制其他脚本
-- ============================================

MAIN_SCRIPT = "aimware_client.lua"
is_main_loaded = false

-- 加载主脚本
function lua_load()
    if is_main_loaded then
        print("[Test] " .. MAIN_SCRIPT .. " 已加载")
        return
    end
    print("[Test] 正在加载 " .. MAIN_SCRIPT .. "...")
    LoadScript(MAIN_SCRIPT)
    is_main_loaded = true
    print("[Test] " .. MAIN_SCRIPT .. " 加载完成")
end

-- 卸载主脚本
function lua_unload()
    if not is_main_loaded then
        print("[Test] " .. MAIN_SCRIPT .. " 未加载")
        return
    end
    print("[Test] 正在卸载 " .. MAIN_SCRIPT .. "...")
    UnloadScript(MAIN_SCRIPT)
    is_main_loaded = false
    print("[Test] " .. MAIN_SCRIPT .. " 已卸载")
end

-- 重新加载主脚本
function lua_reload()
    print("[Test] 重新加载中...")
    lua_unload()
    lua_load()
end

-- 测试 UDP 发送
function test_udp()
    print("[Test] 测试 UDP 发送...")
    
    local udp = network.Socket("UDP")
    if not udp then
        print("[Test] UDP socket 创建失败!")
        return
    end
    
    local test_data = '{"players": [{"name": "Test"}], "map_name": "test"}'
    local ok, size = pcall(function()
        return udp:SendTo("127.0.0.1", 12345, test_data)
    end)
    
    if ok and size > 0 then
        print("[Test] UDP 发送成功! 大小: " .. size .. " bytes")
    else
        print("[Test] UDP 发送失败")
    end
end

-- 测试 entities
function test_entities()
    print("[Test] 测试 entities.FindByClass...")
    local players = entities.FindByClass("CCSPlayer")
    if players then
        print("[Test] 找到 " .. #players .. " 个玩家")
    else
        print("[Test] 未找到玩家 (可能在主菜单)")
    end
end

-- 测试 GetLocalPlayer
function test_localplayer()
    print("[Test] 测试 entities.GetLocalPlayer...")
    local me = entities.GetLocalPlayer()
    if me then
        print("[Test] 本地玩家存在，索引: " .. tostring(me:GetIndex()))
    else
        print("[Test] 本地玩家为 nil (可能在主菜单)")
    end
end

-- 测试所有功能
function test_all()
    print("========================================")
    print(" 开始测试所有功能")
    print("========================================")
    test_localplayer()
    test_entities()
    test_udp()
    print("========================================")
    print(" 测试完成")
    print("========================================")
end

print("========================================")
print(" Aimware Lua 测试工具已加载")
print("========================================")
print("在控制台使用:")
print("  lua_load()    - 加载主脚本")
print("  lua_unload()  - 卸载主脚本")
print("  lua_reload()  - 重新加载主脚本")
print("  test_all()    - 测试所有功能")
print("  test_udp()    - 测试 UDP 发送")
print("  test_entities()    - 测试获取玩家")
print("  test_localplayer() - 测试本地玩家")
print("========================================")

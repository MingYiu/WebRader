-- ========== Probe Script ==========
-- 目的: 找出哪些 Aimware API 會 panic
-- 用法: lua_run 載入此檔,看哪些 print 出來

local PROBE_RESULTS = {}

local function safe_call(name, fn)
    local ok, result = pcall(fn)
    if ok then
        print("[PROBE] " .. name .. " = OK (" .. tostring(result) .. ")")
        PROBE_RESULTS[name] = "OK: " .. tostring(result)
    else
        print("[PROBE] " .. name .. " = ERROR: " .. tostring(result))
        PROBE_RESULTS[name] = "ERROR: " .. tostring(result)
    end
end

print("[PROBE] === AIMWARE API SURVIVAL TEST ===")
print("[PROBE] Stage 1: Basic globals")

-- 嘗試最基本的全局函式(已知 Aimware 提供)
safe_call("type", function() return type(print) end)
safe_call("tostring", function() return tostring(42) end)
safe_call("pcall", function() return pcall(function() return 1 end) end)
safe_call("pairs", function() pairs({1,2,3}); return "pairs ok" end)
safe_call("string.char", function() return string.char(65) end)
safe_call("table.concat", function() return table.concat({"a","b"}, "") end)

print("[PROBE] Stage 2: print still alive?")
print("[PROBE] If you see this line, print() is functional")

print("[PROBE] Stage 3: file API (network.Socket is known-broken)")
safe_call("file.Open", function()
    if file and file.Open then
        return "exists"
    end
    return "file global not found"
end)

safe_call("file.Write", function()
    if file and file.Write then
        return "exists"
    end
    return "file.Write not found"
end)

safe_call("io.open", function()
    if io and io.open then
        return "exists"
    end
    return "io global not found"
end)

print("[PROBE] Stage 4: Game APIs")
safe_call("globals.RealTime", function()
    if globals and globals.RealTime then
        return globals.RealTime()
    end
    return "globals.RealTime not found"
end)

safe_call("entities.GetLocalPlayer", function()
    if entities and entities.GetLocalPlayer then
        local me = entities.GetLocalPlayer()
        return me and "has local player" or "no local player"
    end
    return "entities.GetLocalPlayer not found"
end)

safe_call("callbacks.Register", function()
    if callbacks and callbacks.Register then
        return "exists (NOT CALLED)"
    end
    return "callbacks.Register not found"
end)

safe_call("network.Socket", function()
    if network and network.Socket then
        return "exists (NOT CALLED)"
    end
    return "network global not found"
end)

print("[PROBE] Stage 5.5: Lua version + bitwise support")
safe_call("_VERSION", function() return _VERSION end)
safe_call("bit32", function() return bit32 and "exists" or "not found" end)
safe_call("bit32.band(0xFF, 0x0F)", function() return bit32.band(0xFF, 0x0F) end)
safe_call("bit.tobit(42)", function() return bit and bit.tobit(42) or "no bit lib" end)
safe_call("bit.band(0xFF, 0x0F)", function() return bit.band(0xFF, 0x0F) end)

print("[PROBE] Stage 6: test file write end-to-end")
safe_call("file.Write probe", function()
    if not (file and file.Open) then return "no file API" end
    local f = file.Open("radar_probe.bin", "wb")
    if not f then return "Open returned nil" end
    local r = f:Write("hello world\n")
    f:Close()
    return "wrote: " .. tostring(r)
end)

safe_call("file.Open read", function()
    local f = file.Open("radar_probe.bin", "rb")
    if not f then return "Open(rb) returned nil" end
    local content = f:Read()
    f:Close()
    return "read: " .. tostring(content):sub(1, 30)
end)

print("[PROBE] Stage 7: callbacks.Register actual call")
safe_call("callbacks.Register Draw", function()
    callbacks.Register("Draw", "PROBE_TEST", function() end)
    return "registered OK"
end)

print("[PROBE] Stage 8: engine APIs")
safe_call("engine.GetMapName", function()
    if engine and engine.GetMapName then
        return engine.GetMapName() or "(empty string or nil)"
    end
    return "engine not found"
end)

print("[PROBE] Stage 9: try absolute path / TEMP")
safe_call("file.Open absolute TEMP", function()
    local tmp = os.getenv("TEMP") or os.getenv("TMP")
    if not tmp then return "no TEMP env" end
    local p = tmp .. "\\radar_probe.bin"
    local f, err = file.Open(p, "wb")
    if not f then return "Open failed: " .. tostring(err) .. " path=" .. p end
    f:Write("ok")
    f:Close()
    return "wrote to: " .. p
end)

safe_call("file.Open CWD with subdir", function()
    local f, err = file.Open("csgo\\radar_probe.bin", "wb")
    if not f then return "Open failed: " .. tostring(err) end
    f:Write("ok")
    f:Close()
    return "wrote to csgo/radar_probe.bin"
end)

safe_call("file.Open CSGO dir direct", function()
    local f, err = file.Open("csgo/radar_probe.bin", "wb")
    if not f then return "Open failed: " .. tostring(err) end
    f:Write("ok")
    f:Close()
    return "wrote to csgo/radar_probe.bin (slash)"
end)

safe_call("os.getenv", function()
    return os.getenv("TEMP") or os.getenv("TMP") or "no temp"
end)

safe_call("engine.GetGameDir", function()
    if engine and engine.GetGameDir then
        return tostring(engine.GetGameDir())
    end
    return "engine.GetGameDir not found"
end)

print("[PROBE] Stage 10: hunt for writable absolute path")
safe_call("globals.GetAppDataDir", function()
    if globals and globals.GetAppDataDir then return tostring(globals.GetAppDataDir()) end
    return "no globals.GetAppDataDir"
end)
safe_call("globals.GetWorkingDir", function()
    if globals and globals.GetWorkingDir then return tostring(globals.GetWorkingDir()) end
    return "no globals.GetWorkingDir"
end)
safe_call("globals.GetModuleDir", function()
    if globals and globals.GetModuleDir then return tostring(globals.GetModuleDir()) end
    return "no globals.GetModuleDir"
end)
safe_call("client.GetInstallPath", function()
    if client and client.GetInstallPath then return tostring(client.GetInstallPath()) end
    return "no client.GetInstallPath"
end)
safe_call("client.GetRootDirectory", function()
    if client and client.GetRootDirectory then return tostring(client.GetRootDirectory()) end
    return "no client.GetRootDirectory"
end)
safe_call("engine.GetModDirectory", function()
    if engine and engine.GetModDirectory then return tostring(engine.GetModDirectory()) end
    return "no engine.GetModDirectory"
end)
safe_call("engine.GetGameDirectory", function()
    if engine and engine.GetGameDirectory then return tostring(engine.GetGameDirectory()) end
    return "no engine.GetGameDirectory"
end)

-- Globals walk: find anything mentioning path/dir/install/working
safe_call("globals: list path-ish keys", function()
    if not globals then return "no globals" end
    local found = {}
    for k, v in pairs(globals) do
        local lk = k:lower()
        if lk:find("path") or lk:find("dir") or lk:find("install") or lk:find("working") or lk:find("module") or lk:find("appdata") then
            found[#found + 1] = tostring(k)
        end
    end
    return "found keys: " .. table.concat(found, ",")
end)

-- Try Aimware's known log/cache paths (this is the historic cheat install dir)
safe_call("file.Open Aimware dir absolute", function()
    local p = [[C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\bin\win64\radar_probe.bin]]
    local f, err = file.Open(p, "wb")
    if not f then return "failed: " .. tostring(err) end
    f:Write("ok")
    f:Close()
    return "wrote: " .. p
end)

safe_call("file.Open drive root", function()
    local p = [[C:\radar_probe.bin]]
    local f, err = file.Open(p, "wb")
    if not f then return "failed: " .. tostring(err) end
    f:Write("ok")
    f:Close()
    return "wrote: " .. p
end)

safe_call("file.Open Windows dir", function()
    local p = [[C:\Windows\Temp\radar_probe.bin]]
    local f, err = file.Open(p, "wb")
    if not f then return "failed: " .. tostring(err) end
    f:Write("ok")
    f:Close()
    return "wrote: " .. p
end)

safe_call("file.Open .txt extension", function()
    -- maybe only .txt allowed?
    local f, err = file.Open("radar_probe.txt", "wb")
    if not f then return "failed: " .. tostring(err) end
    f:Write("ok")
    f:Close()
    return "wrote radar_probe.txt"
end)

safe_call("file.Open UPPERCASE", function()
    local f, err = file.Open("RADAR_PROBE.BIN", "wb")
    if not f then return "failed: " .. tostring(err) end
    f:Write("ok")
    f:Close()
    return "wrote RADAR_PROBE.BIN"
end)

safe_call("file.Open dots removed", function()
    local f, err = file.Open("radarprobe", "wb")
    if not f then return "failed: " .. tostring(err) end
    f:Write("ok")
    f:Close()
    return "wrote radarprobe"
end)

print("[PROBE] Stage 11: readback round-trip with .txt + more extensions")
safe_call("file.Open/read round-trip .txt", function()
    local f = file.Open("radar_probe.txt", "wb")
    if not f then return "Open wb failed" end
    f:Write("HELLO FROM AIMWARE LUA\n")
    f:Close()
    local r = file.Open("radar_probe.txt", "rb")
    if not r then return "Open rb failed" end
    local content = r:Read()
    r:Close()
    return "roundtrip: " .. tostring(content):sub(1, 40)
end)

-- Test allowed extensions whitelist
for _, ext in ipairs({".log", ".cfg", ".ini", ".json", ".lua", ".dat", ".txt", ".csv", ".xml", ".html", ".bin", ".txt"}) do
    safe_call("test " .. ext, function()
        local name = "radar_test" .. ext
        local f = file.Open(name, "wb")
        if not f then return name .. " REJECTED" end
        f:Write("x")
        f:Close()
        return name .. " OK"
    end)
end

print("[PROBE] === END STAGE 11 ===")
print("[PROBE] Copy all [PROBE] lines from console and paste them back to me")
print("[PROBE] I'll figure out which transport to use based on which APIs survive")
-- probe3.lua — verify if f:Write actually writes despite nil return
-- Also check if there's another write API on this build.

local function safe(name, fn)
    print("==== " .. name .. " ====")
    local ok, err = pcall(fn)
    if not ok then print("  FAIL: " .. tostring(err)) end
end

-- 1) Write + IMMEDIATELY read back, check actual file content
safe("write 'a' then read back", function()
    local f = file.Open("radar_packet.txt", "wb")
    if not f then error("open wb failed") end
    local w = f:Write("a")
    print("  Write returned: " .. tostring(w))
    f:Close()
    -- Now read
    local rf, rerr = file.Open("radar_packet.txt", "rb")
    if not rf then
        print("  read open failed: " .. tostring(rerr))
        return
    end
    local content, rerr2 = rf:Read()
    print("  Read returned: " .. tostring(content) .. " (len=" .. tostring(content and #content or "?") .. ")")
    print("  Read error: " .. tostring(rerr2))
    rf:Close()
end)

-- 2) Try f:WriteLine instead
safe("f:WriteLine 'hello'", function()
    local f = file.Open("radar_packet.txt", "wb")
    if not f then error("open wb failed") end
    if f.WriteLine then
        local w = f:WriteLine("hello")
        print("  WriteLine returned: " .. tostring(w))
    else
        print("  f.WriteLine NOT a method")
    end
    f:Close()
    local rf = file.Open("radar_packet.txt", "rb")
    if rf then
        local c = rf:Read()
        print("  Read back: " .. tostring(c))
        rf:Close()
    end
end)

-- 3) Check ALL file methods / attributes via metatable
safe("metatable dump on file handle", function()
    local f = file.Open("radar_packet.txt", "wb")
    if not f then error("open wb failed") end
    local mt = getmetatable(f)
    if mt then
        local keys = {}
        for k in pairs(mt) do keys[#keys+1] = tostring(k) end
        print("  handle mt keys: " .. table.concat(keys, ", "))
        local idx = mt.__index
        if idx and type(idx) == "table" then
            local idxkeys = {}
            for k in pairs(idx) do idxkeys[#idxkeys+1] = tostring(k) end
            print("  mt.__index keys: " .. table.concat(idxkeys, ", "))
        end
    else
        print("  no metatable")
    end
    -- Also try direct attributes
    for _, attr in ipairs({"Write", "WriteLine", "WriteString", "Print", "Flush", "Close", "Read", "ReadLine", "Size", "Seek", "Tell"}) do
        print("  f." .. attr .. " = " .. type(f[attr]))
    end
    f:Close()
end)

-- 4) Probe file.* globals (module-level API)
safe("file module globals", function()
    if type(file) ~= "table" then
        print("  file global is not a table: " .. type(file))
        return
    end
    local keys = {}
    for k in pairs(file) do keys[#keys+1] = tostring(k) end
    print("  file.* keys: " .. table.concat(keys, ", "))
end)

-- 5) Try io.* (Lua 5.1 standard) — Aimware usually overrides but worth trying
safe("io.open", function()
    if not io or not io.open then
        print("  io module not available")
        return
    end
    local f, err = io.open("radar_packet.txt", "wb")
    if not f then
        print("  io.open failed: " .. tostring(err))
        return
    end
    local ok, werr = f:write("hello from io")
    print("  io:write returned: " .. tostring(ok))
    print("  io:write err: " .. tostring(werr))
    f:close()
end)

print("==== probe3 done ====")

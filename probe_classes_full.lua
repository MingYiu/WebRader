-- probe_classes_full.lua — full entity class scan
local function safe(obj, name, ...)
    if not obj then return "NO" end
    local m = obj[name]
    if not m then return "NO_METHOD" end
    local ok, res = pcall(m, obj, ...)
    if not ok then return "ERR" end
    return tostring(res):sub(1, 60)
end

local cb
cb = function()
    callbacks.Unregister("Draw", "probe_classes_full_cb")
    print("========== PROBE CLASSES FULL START ==========")

    -- Get max entity index
    print("[limits]")
    local max_idx = 0
    for _, n in ipairs({"GetMaxEntities","GetMaxIndex","GetHighestEntityIndex","GetEntityCount","GetPlayerLimit","GetMaxClients"}) do
        local v = safe(entities, n)
        print("  entities:" .. n .. " = " .. tostring(v))
    end

    -- Show globals.TickCount
    if globals and globals.TickCount then
        print("  globals.TickCount = " .. tostring(globals.TickCount))
    end

    -- Map class -> count
    print("[class histogram (sample up to 4096)]")
    local hist = {}
    local last_valid = 0
    for i = 0, 4095 do
        local ok, e = pcall(function() return entities.GetByIndex(i) end)
        if ok and e then
            last_valid = i
            local class = safe(e, "GetClass") or "unknown"
            hist[class] = (hist[class] or 0) + 1
        end
    end
    print("  last_valid index = " .. last_valid)

    -- Print top 60 classes
    local sorted = {}
    for c, n in pairs(hist) do table.insert(sorted, {c, n}) end
    table.sort(sorted, function(a, b) return a[2] > b[2] end)
    for i = 1, math.min(60, #sorted) do
        print(string.format("  %5d  %s", sorted[i][2], sorted[i][1]))
    end

    -- Try 2048..8192 too (some aimware builds have higher max)
    print("[scan 4096..8192]")
    local n_high = 0
    for i = 4096, 8191 do
        local ok, e = pcall(function() return entities.GetByIndex(i) end)
        if ok and e then
            n_high = n_high + 1
            if n_high <= 10 then
                print("  i=" .. i .. " class=" .. tostring(safe(e, "GetClass")))
            end
        end
    end
    print("  total in 4096-8192: " .. n_high)

    print("========== PROBE CLASSES FULL END ==========")
end
callbacks.Register("Draw", "probe_classes_full_cb", cb)
-- probe_api.lua — minimal: just print every global we can see
local cb
cb = function()
    callbacks.Unregister("Draw", "probe_api_cb")
    print("========== PROBE API START ==========")

    -- Show types of common globals
    local names = {
        "entities","entitylist","client","clientstate","panorama","ui",
        "globals","engine","cvar","cvars","callbacks","events",
        "renderer","render","materials","vector","clientlog","gamescenarios",
        "http","json","filesystem","file"
    }
    print("--- globals ---")
    for _, n in ipairs(names) do
        local v = _G[n]
        print(string.format("  _G.%s = %s", n, type(v)))
    end

    -- Try to get local player via every conceivable way
    print("--- get local player ---")
    local me = nil
    if entities then
        local mt = getmetatable(entities)
        print("  entities mt = " .. type(mt))
        if type(entities) == "table" then
            for k, v in pairs(entities) do print("    entities." .. tostring(k) .. " = " .. type(v)) end
        end
        me = entities.GetLocalPlayer and entities.GetLocalPlayer() or nil
    end
    print("  me = " .. tostring(me) .. " (type=" .. type(me) .. ")")

    if me then
        -- Iterate metatable without crashing
        local mt = getmetatable(me)
        print("  me mt = " .. type(mt))
        if type(mt) == "table" then
            local n = 0
            for k, v in pairs(mt) do
                n = n + 1
                if n <= 80 then
                    print(string.format("    me:%s = %s", tostring(k), type(v)))
                end
            end
            print("    total: " .. n)
        end
    end

    print("========== PROBE API END ==========")
end
callbacks.Register("Draw", "probe_api_cb", cb)
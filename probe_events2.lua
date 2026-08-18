-- probe_events2.lua — directly call event-related methods, no calls to GetGameEventManager if it doesn't exist
local function safe(obj, name, ...)
    if not obj then return "nil" end
    local m = obj[name]
    if not m then return "NO_METHOD" end
    local ok, res = pcall(m, obj, ...)
    if not ok then return "ERR:" .. tostring(res):sub(1,80) end
    return "OK:" .. type(res) .. ":" .. tostring(res):sub(1,80)
end

local cb
cb = function()
    callbacks.Unregister("Draw", "probe_events2_cb")
    print("========== PROBE EVENTS 2 START ==========")

    -- DUMP all entities.* methods
    print("[entities.* full list]")
    for k, v in pairs(entities) do
        print("  " .. tostring(k) .. " = " .. type(v))
    end

    -- Try to call every event-related method on entities
    print("[calling event methods on entities]")
    local event_guesses = {
        "GetGameEventManager","GetEventManager","GetEvents","GetAllEvents",
        "GetEvent","RegisterEvent","ListenEvent","SubscribeEvent",
        "OnEvent","HookEvent","AddListener",
    }
    for _, name in ipairs(event_guesses) do
        local r = safe(entities, name)
        print("  entities:" .. name .. " -> " .. r)
    end

    -- Listen on client
    print("[client.*]")
    for k, v in pairs(client) do
        print("  client." .. tostring(k) .. " = " .. type(v))
    end

    -- See if ui exists somewhere
    print("[scanning common global namespaces]")
    for _, name in ipairs({"ui","UI","panorama","Panorama","event","callback","Callback","messages","MessageBus"}) do
        if _G[name] ~= nil then print("  _G." .. name .. " = " .. type(_G[name])) end
    end

    -- Final attempt: maybe events is registered under callbacks
    print("[callbacks]")
    local t = type(callbacks)
    print("  callbacks type = " .. t)
    if t == "table" then
        local n = 0
        for k, v in pairs(callbacks) do
            n = n + 1
            if n <= 30 then print("  callbacks." .. tostring(k) .. " = " .. type(v)) end
        end
        print("  total = " .. n)
    elseif t == "userdata" then
        local mt = getmetatable(callbacks)
        print("  callbacks mt = " .. type(mt))
        if type(mt) == "table" then
            for k, v in pairs(mt) do print("  callbacks mt." .. tostring(k) .. " = " .. type(v)) end
        end
    end

    print("========== PROBE EVENTS 2 END ==========")
end
callbacks.Register("Draw", "probe_events2_cb", cb)
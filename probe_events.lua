-- probe_events.lua — check if events API works in this aimware build
local cb
cb = function()
    callbacks.Unregister("Draw", "probe_events_cb")
    print("========== PROBE EVENTS START ==========")

    -- Check globals
    print("[globals]")
    for _, name in ipairs({"events","eventmanager","gameeventmanager","gameevents","clientevents","game_eventmanager"}) do
        local v = _G[name]
        print("  _G." .. name .. " = " .. type(v))
    end

    -- Check entity namespace for event-related
    print("[entities namespace extras]")
    for k, v in pairs(entities) do
        if type(k) == "string" and (k:find("Event") or k:find("event") or k:find("Find") or k:find("Get")) then
            print("  entities." .. k .. " = " .. type(v))
        end
    end

    -- Try events.GetGameEventManager if exists
    local test_funcs = {
        function()
            return type(events) == "table" and events.GetGameEventManager and events.GetGameEventManager()
        end,
        function()
            return type(events) == "table" and events.GetAllEvents and events.GetAllEvents()
        end,
        function()
            return type(events) == "table" and events.GetEvent and events.GetEvent("player_death")
        end,
        function()
            return type(entities) == "table" and entities.GetGameEventManager and entities.GetGameEventManager()
        end,
    }
    for i, fn in ipairs(test_funcs) do
        local ok, res = pcall(fn)
        print("  test_funcs[" .. i .. "] ok=" .. tostring(ok) .. " res=" .. type(res) .. " val=" .. tostring(res):sub(1,40))
    end

    -- Try callback registration for a known event
    print("[try registering event callbacks]")
    if events then
        for _, name in ipairs({"weapon_fire","item_purchase","bomb_pickup","bomb_dropped","player_death","round_start","player_hurt"}) do
            local ok, err = pcall(function()
                if events.Register then
                    events.Register(name, function(e) end)
                end
            end)
            print("  events.Register " .. name .. " ok=" .. tostring(ok))
        end
    end

    -- Try the various callback names that aimware typically exposes
    print("[event-style globals]")
    for _, name in ipairs({"gameevent","event","cl_events","client_events","server_events","game_events"}) do
        local v = _G[name]
        if v ~= nil then print("  _G." .. name .. " = " .. type(v)) end
    end

    -- See if callbacks.Register has a different signature for events
    print("[callbacks namespace]")
    for k, v in pairs(callbacks) do
        print("  callbacks." .. k .. " = " .. type(v))
    end

    print("========== PROBE EVENTS END ==========")
end
callbacks.Register("Draw", "probe_events_cb", cb)
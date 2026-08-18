-- Probe whether FireGameEvent / events.* works on this build.
-- Tests payload accessors: GetName, GetInt, GetString, GetFloat, etc.

local events_seen = {}
local listeners_active = false

local function activate_listeners()
    if listeners_active then return end
    listeners_active = true

    local ok = pcall(function()
        -- Register via callbacks (assume working like earlier code does)
        callbacks.Register("FireGameEvent", "ProbeEventsRound", function(event)
            local name = "<no name>"
            pcall(function() name = event:GetName() end)

            -- Only dump events we care about, not every bullet fire
            local care = {
                round_start = true, round_end = true, round_time_warning = true,
                cs_round_final_beep = true, cs_win_panel_match = true,
                bomb_planted = true, bomb_begindefuse = true,
                bomb_abortdefuse = true, bomb_defused = true, bomb_exploded = true,
                player_connect_full = true, player_disconnect = true,
                game_newmap = true, game_start = true, cs_match_start = true,
                announce_phase_end = true,
                cs_pre_restart = true,
                cs_match_end_restart = true,
                cs_game_disconnected = true,
                enter_buyzone = true, exit_buyzone = true,
            }
            if not care[name] then return end

            -- Dump all keys/values
            local dump = { "[name=" .. name .. "]" }
            for i = 0, 8 do
                local sk, sv = pcall(function() return event:GetString(tostring(i)) end)
                if sk and sv and sv ~= "" then
                    table.insert(dump, "s" .. i .. "=" .. tostring(sv))
                end
                local ik, iv = pcall(function() return event:GetInt(tostring(i)) end)
                if ik and iv and iv ~= 0 then
                    table.insert(dump, "i" .. i .. "=" .. tostring(iv))
                end
                local fk, fv = pcall(function() return event:GetFloat(tostring(i)) end)
                if fk and fv and math.abs(fv) > 0.0001 then
                    table.insert(dump, "f" .. i .. "=" .. string.format("%.2f", fv))
                end
            end
            print("[EVENT] " .. table.concat(dump, " "))
        end)
    end)

    if not ok then
        print("[PROBE] callbacks.Register for FireGameEvent FAILED")
    else
        print("[PROBE] FireGameEvent listener registered")
    end

    -- Also try events.Register as alternative
    local ok2 = pcall(function()
        if events and events.Register then
            events.Register("ProbeEvents2", function(event)
                pcall(function()
                    local n = type(event) == "userdata" and event.GetName and event:GetName() or event
                    print("[EVENT2] " .. tostring(n))
                end)
            end)
        end
    end)
    print("[PROBE] events.Register fallback: " .. tostring(ok2))
end

local function safe(label, fn)
    local ok, val = pcall(fn)
    if ok and val ~= nil then
        local s = type(val)
        if type(val) == "userdata" then s = "userdata" end
        print(label .. " = OK:" .. s)
    else
        print(label .. " = NO_METHOD")
    end
end

print("========== PROBE EVENTS START ==========")

-- Discover API surface for events / callbacks
safe("[callbacks.Register]", function() return type(callbacks.Register) end)
safe("[callbacks.Unregister]", function() return type(callbacks.Unregister) end)
safe("[events.Register]", function() return type(events.Register) end)
safe("[events]", function() return type(events) end)
safe("[event.GetName]", function()
    -- Try to construct a fake event: there isn't one, so this will fail
    return nil
end)

activate_listeners()
print("========== PROBE EVENTS READY (waiting for in-game action) ==========")
print("Trigger any round events, then watch output.")
print("Reload to stop probing (listener persists until reload).")
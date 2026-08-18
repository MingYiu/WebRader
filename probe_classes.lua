-- probe_classes.lua — test on entities listed via different APIs and check class hierarchy
local function safe(obj, name, ...)
    local m = obj and obj[name]
    if not m then return "NO" end
    local ok, res = pcall(m, obj, ...)
    if not ok then return "ERR:" .. tostring(res):sub(1,80) end
    return "OK:" .. type(res) .. ":" .. tostring(res):sub(1,100)
end

local cb
cb = function()
    callbacks.Unregister("Draw", "probe_classes_cb")
    print("========== PROBE CLASSES START ==========")

    -- Test on local player
    local me = entities.GetLocalPlayer()
    print("[me] class=" .. tostring(safe(me, "GetClass")) ..
          " name=" .. tostring(safe(me, "GetName")) ..
          " health=" .. tostring(safe(me, "GetHealth")) ..
          " alive=" .. tostring(safe(me, "IsAlive")) ..
          " team=" .. tostring(safe(me, "GetTeamNumber")))

    -- Test on observed target (since we're observer)
    local obs = safe(me, "GetObserverTarget")
    print("[observer target] " .. tostring(obs))

    -- Check entities namespace functions
    print("[entities.* funcs]")
    for k, v in pairs(entities) do
        print("  entities." .. tostring(k) .. " = " .. type(v))
    end

    -- Check client namespace
    print("[client.* funcs]")
    if client then
        for k, v in pairs(client) do
            print("  client." .. tostring(k) .. " = " .. type(v))
        end
    end

    -- Now try ALL world entities by index and find the ones that return alive players
    print("[scan entities by index for live players]")
    local found = 0
    for i = 0, 2048 do
        local ok, e = pcall(function() return entities.GetByIndex(i) end)
        if ok and e then
            local alive = safe(e, "IsAlive")
            local class = safe(e, "GetClass") or ""
            local name = safe(e, "GetName") or ""
            if class:find("Player") or class:find("Pawn") then
                if found < 6 then
                    print(string.format("  i=%d class=%s name=%s alive=%s team=%s health=%s",
                        i, class, name, alive,
                        tostring(safe(e, "GetTeamNumber")),
                        tostring(safe(e, "GetHealth"))))
                end
                found = found + 1
            end
        end
    end
    print("  total player-like entities: " .. found)

    -- On a found alive player, dump EVERY method by trying common names
    print("[methods on first alive player pawn]")
    local sample = nil
    for i = 0, 2048 do
        local ok, e = pcall(function() return entities.GetByIndex(i) end)
        if ok and e then
            local class = safe(e, "GetClass") or ""
            local alive = safe(e, "IsAlive") == "OK:true"
            if alive and class:find("Player") then
                sample = e
                break
            end
        end
    end
    if sample then
        local method_names = {
            "GetIndex","GetName","GetClass","GetAbsOrigin","IsAlive","GetHealth","GetTeamNumber",
            "GetActiveWeapon","GetActiveWeaponName","GetWeapons","GetMyWeapons","GetWeapon",
            "GetWeaponEntity","GetWeaponBySlot","GetWeaponsBySlot","GetSlotWeapon","GetWeaponsAll",
            "GetPlayerName","GetSteamID","GetPlayerSteamID","GetTeam","GetMaxHealth",
            "GetArmor","GetVelocity","GetEyeAngles","GetViewAngles","GetAngles","GetFlags",
            "IsBot","IsDormant","IsValid","GetOwner","GetOrigin","GetMins","GetMaxs",
            "GetProp","GetPropInt","GetPropFloat","GetPropString","GetPropVector","GetPropEntity",
            "GetNetProp","GetNetPropInt","GetNetPropString",
            "HasWeapon","GetCurrentWeapon",
        }
        for _, name in ipairs(method_names) do
            local m = sample[name]
            if m then
                local ok2, res = pcall(m, sample)
                local preview = type(res) == "string" and res:sub(1,40) or tostring(res):sub(1,40)
                print(string.format("  %s -> OK [%s] %s", name, type(res), preview))
            end
        end
    else
        print("  no alive player pawn found to probe")
    end

    print("========== PROBE CLASSES END ==========")
end
callbacks.Register("Draw", "probe_classes_cb", cb)
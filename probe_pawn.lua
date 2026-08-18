-- probe_pawn.lua — find the actual player pawns and check weapon methods
local function safe(obj, name, ...)
    if not obj then return "NO" end
    local m = obj[name]
    if not m then return "NO" end
    local ok, res = pcall(m, obj, ...)
    if not ok then return "ERR" end
    return "OK:" .. type(res) .. ":" .. tostring(res):sub(1,80)
end

local cb
cb = function()
    callbacks.Unregister("Draw", "probe_pawn_cb")
    print("========== PROBE PAWN START ==========")

    local me = entities.GetLocalPlayer()
    print("[me methods on alive C_CSPlayerPawn]")
    local method_names = {
        "GetIndex","GetName","GetClass","GetAbsOrigin","IsAlive","GetHealth","GetTeamNumber","GetSteamID",
        "GetActiveWeapon","GetActiveWeaponName","GetWeapons","GetMyWeapons","GetWeapon",
        "GetWeaponEntity","GetWeaponBySlot","GetWeaponsBySlot","GetSlotWeapon","GetWeaponsAll",
        "GetPlayerName","GetPlayerSteamID","GetTeam","GetMaxHealth",
        "GetArmor","GetVelocity","GetEyeAngles","GetViewAngles","GetAngles","GetFlags","IsBot",
        "GetProp","GetPropInt","GetPropFloat","GetPropString","GetPropVector","GetPropEntity",
        "GetNetProp","GetNetPropInt","GetNetPropString",
        "HasWeapon","GetCurrentWeapon","GetOwnerEntity","GetOwner",
        "GetWeaponsCount","GetWeaponInSlot",
    }
    for _, name in ipairs(method_names) do
        local m = me[name]
        if m then
            local ok, res = pcall(m, me)
            local preview = type(res) == "string" and res:sub(1,40) or tostring(res):sub(1,40)
            print(string.format("  me:%s -> OK [%s] %s", name, type(res), preview))
        end
    end

    -- Find a C_CSPlayerPawn (the actual world pawn) and probe on it
    print("[scan for actual Pawn entities]")
    local found_pawns = 0
    for i = 0, 2048 do
        local ok, e = pcall(function() return entities.GetByIndex(i) end)
        if ok and e then
            local class = safe(e, "GetClass") or ""
            if class:find("CSPlayerPawn") or class:find("PlayerPawn") then
                local alive = safe(e, "IsAlive")
                local health = safe(e, "GetHealth") or ""
                local team = safe(e, "GetTeamNumber") or ""
                local name = safe(e, "GetName") or ""
                if found_pawns < 5 then
                    print(string.format("  i=%d class=%s name=%s alive=%s team=%s hp=%s",
                        i, class, name, alive, team, health))
                end
                found_pawns = found_pawns + 1
            end
        end
    end
    print("  total pawn entities: " .. found_pawns)

    -- Now: scan for alive pawn specifically and probe weapon methods
    print("[probe weapon methods on first alive pawn]")
    for i = 0, 2048 do
        local ok, e = pcall(function() return entities.GetByIndex(i) end)
        if ok and e then
            local class = safe(e, "GetClass") or ""
            local alive = safe(e, "IsAlive") == "OK:boolean:true"
            if alive and class:find("PlayerPawn") then
                print("  Trying methods on pawn i=" .. i .. " class=" .. class)
                -- ALL these methods on the pawn directly
                for _, name in ipairs(method_names) do
                    local m = e[name]
                    if m then
                        local ok2, res = pcall(m, e)
                        local preview = type(res) == "string" and res:sub(1,40) or tostring(res):sub(1,40)
                        print(string.format("    pawn:%s -> OK [%s] %s", name, type(res), preview))
                    end
                end
                break
            end
        end
    end

    print("========== PROBE PAWN END ==========")
end
callbacks.Register("Draw", "probe_pawn_cb", cb)
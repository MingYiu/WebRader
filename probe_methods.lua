-- probe_methods.lua — actually CALL methods on me to see what exists
local function try_call(obj, name, ...)
    local method = obj[name]
    if not method then return "NO_METHOD" end
    local ok, res = pcall(method, obj, ...)
    if not ok then return "ERR: " .. tostring(res) end
    return "OK: " .. tostring(res) .. " (type=" .. type(res) .. ")"
end

local cb
cb = function()
    callbacks.Unregister("Draw", "probe_methods_cb")
    print("========== PROBE METHODS START ==========")

    local me = entities.GetLocalPlayer()
    if not me then print("no me") return end

    -- Known-good
    print("[baseline]")
    print("  GetIndex:", try_call(me, "GetIndex"))
    print("  GetName:", try_call(me, "GetName"))
    print("  GetClass:", try_call(me, "GetClass"))
    print("  GetAbsOrigin:", try_call(me, "GetAbsOrigin"))
    print("  IsAlive:", try_call(me, "IsAlive"))

    -- Prop API (we know this FAILS but log exact error)
    print("[prop API]")
    print("  GetPropInt m_iTeam:", try_call(me, "GetPropInt", "m_iTeam"))
    print("  GetPropEntity m_hActiveWeapon:", try_call(me, "GetPropEntity", "m_hActiveWeapon"))
    print("  GetPropString:", try_call(me, "GetPropString", "m_szName"))

    -- Weapon guesses
    print("[weapon guesses]")
    print("  GetActiveWeapon:", try_call(me, "GetActiveWeapon"))
    print("  GetActiveWeaponName:", try_call(me, "GetActiveWeaponName"))
    print("  GetWeapon:", try_call(me, "GetWeapon"))
    print("  GetWeapons:", try_call(me, "GetWeapons"))
    print("  GetMyWeapons:", try_call(me, "GetMyWeapons"))
    print("  GetWeaponEntity:", try_call(me, "GetWeaponEntity"))

    -- Player info helpers
    print("[player info]")
    print("  GetPlayerName:", try_call(me, "GetPlayerName"))
    print("  GetPlayerSteamID:", try_call(me, "GetPlayerSteamID"))
    print("  GetSteamID:", try_call(me, "GetSteamID"))
    print("  GetTeam:", try_call(me, "GetTeam"))
    print("  GetPlayerTeam:", try_call(me, "GetPlayerTeam"))
    print("  GetTeamNumber:", try_call(me, "GetTeamNumber"))
    print("  GetHealth:", try_call(me, "GetHealth"))
    print("  GetArmor:", try_call(me, "GetArmor"))
    print("  GetFlags:", try_call(me, "GetFlags"))
    print("  GetVelocity:", try_call(me, "GetVelocity"))
    print("  GetEyeAngles:", try_call(me, "GetEyeAngles"))
    print("  GetAngles:", try_call(me, "GetAngles"))
    print("  GetViewOffset:", try_call(me, "GetViewOffset"))

    print("========== PROBE METHODS END ==========")
end
callbacks.Register("Draw", "probe_methods_cb", cb)
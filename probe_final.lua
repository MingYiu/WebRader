-- probe_final.lua — exhaustive final check on weapon retrieval
local function safe(obj, name, ...)
    if not obj then return "NO" end
    local m = obj[name]
    if not m then return "NO_METHOD" end
    local ok, res = pcall(m, obj, ...)
    if not ok then return "ERR" end
    return "OK:" .. type(res) .. ":" .. tostring(res):sub(1,80)
end

local cb
cb = function()
    callbacks.Unregister("Draw", "probe_final_cb")
    print("========== PROBE FINAL START ==========")

    -- Get local player pawn
    local me = entities.GetLocalPlayer()
    if not me then
        print("NO local player")
        return
    end
    print("[local player] class=" .. safe(me, "GetClass") .. " name=" .. safe(me, "GetName"))

    -- Check all properties starting with m_Weapon, m_hActive, m_hMyWeapons, etc.
    print("[trying weapon-related props on player]")
    local prop_names = {
        "m_hActiveWeapon","m_hMyWeapons","m_hActiveWeaponHandle",
        "m_WeaponServices","m_pWeaponServices","m_ActiveWeapon",
        "m_Item","m_iAccountID","m_iTeamNum","m_iHealth",
        "m_iCompetitiveRanking","m_iCompetitiveWins",
        "m_iPlayerVIP","m_flFlashDuration","m_flFlashMaxAlpha",
        "m_angEyeAngles","m_angRotation","m_aimPunchAngle",
        "m_aimPunchAngleVel","m_viewPunchAngle",
    }
    for _, p in ipairs(prop_names) do
        local r = safe(me, "GetPropInt", p)
        if r ~= "NO_METHOD" then print("  int " .. p .. " = " .. r) end
        local r2 = safe(me, "GetPropFloat", p)
        if r2 ~= "NO_METHOD" then print("  float " .. p .. " = " .. r2) end
        local r3 = safe(me, "GetPropString", p)
        if r3 ~= "NO_METHOD" then print("  string " .. p .. " = " .. r3) end
        local r4 = safe(me, "GetPropEntity", p)
        if r4 ~= "NO_METHOD" then print("  entity " .. p .. " = " .. r4) end
    end

    -- Try the high-level direct methods
    print("[direct methods on local player]")
    local methods = {
        "GetActiveWeapon","GetActiveWeaponName","GetActiveWeaponIndex",
        "GetMyWeapons","GetWeapons","GetAllWeapons","GetWeaponBySlot",
        "GetWeaponInSlot","GetWeaponByIndex","GetWeaponEntity",
        "GetEyeAngles","GetAngles","GetRotation","GetAimPunch",
        "GetViewPunch","GetPunch","GetEyeAngle",
        "GetFlashDuration","GetFlashAlpha","GetFlashMaxAlpha",
        "GetArmor","GetHelmet","GetHasHelmet","GetHasDefuser",
        "GetHasBomb","GetHaveBomb","GetIsDefusing",
        "GetMoney","GetCash","GetScore","GetKills","GetDeaths",
        "GetAssists","GetMVPs","GetPing",
    }
    for _, m in ipairs(methods) do
        local r = safe(me, m)
        if r ~= "NO_METHOD" then print("  " .. m .. " = " .. r) end
    end

    -- Try same on local player pawn if different
    print("[local player pawn (if different)]")
    local players = entities.FindByClass("CCSPlayerController")
    if players and players[1] then
        local first = players[1]
        print("  found controller, class=" .. safe(first, "GetClass"))
        for _, m in ipairs({"GetPawn","GetPlayerPawn","GetPlayerEntity","GetObserverPawn"}) do
            local r = safe(first, m)
            if r ~= "NO_METHOD" then print("  " .. m .. " = " .. r) end
        end
    end

    -- Try entities.GetLocalPlayer variants
    for _, name in ipairs({"GetLocalPlayer","GetLocalController","GetLocalPawn","GetPlayer","GetMe","GetLocalEntity"}) do
        local r = safe(entities, name)
        if r ~= "NO_METHOD" then print("  entities:" .. name .. " = " .. r) end
        local r2 = safe(client, name)
        if r2 ~= "NO_METHOD" then print("  client:" .. name .. " = " .. r2) end
    end

    print("========== PROBE FINAL END ==========")
end
callbacks.Register("Draw", "probe_final_cb", cb)
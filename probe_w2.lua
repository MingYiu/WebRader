-- probe_w2.lua — fixed: force-find ANY C_Weapon or C_Knife, log per-index
local function safe(obj, name)
    if not obj then return "NO_OBJ" end
    local m = obj[name]
    if not m then return "NO_METHOD" end
    local ok, res = pcall(m, obj)
    if not ok then return "ERR" end
    return "OK:" .. type(res) .. ":" .. tostring(res):sub(1,60)
end

local cb
cb = function()
    callbacks.Unregister("Draw", "probe_w2_cb")
    print("========== PROBE W2 START ==========")

    -- Try EVERY entity 0..500 and print class
    local weapons = {}
    for i = 0, 500 do
        local ok, e = pcall(function() return entities.GetByIndex(i) end)
        if ok and e then
            local cls = safe(e, "GetClass")
            -- store regardless
            if cls:find("Weapon") or cls:find("Knife") or cls:find("C4") or cls:find("Bomb") or cls:find("Grenade") or cls:find("Flash") or cls:find("HE") then
                table.insert(weapons, {i = i, cls = cls})
            end
        end
    end
    print("  weapons found: " .. #weapons)
    for _, w in ipairs(weapons) do
        print("  i=" .. w.i .. " cls=" .. w.cls)
    end

    if #weapons == 0 then
        print("NO weapon")
        print("========== PROBE W2 END ==========")
        return
    end

    -- Probe first weapon
    local e = entities.GetByIndex(weapons[1].i)
    print("[first weapon methods] i=" .. weapons[1].i .. " cls=" .. weapons[1].cls)
    local methods = {
        "GetIndex","GetName","GetClass","GetAbsOrigin","IsAlive",
        "GetOwner","GetOwnerEntity","GetOwnerHandle","GetPlayerOwner",
        "GetPlayerOwnerEntity","GetHoldingPlayer","GetOwningPlayer",
        "GetOwnerPlayer","GetEntOwner","GetOwningEntity",
        "GetClip1","GetClip2","GetReserveAmmo","GetAmmo","GetAmmoInClip",
        "GetNextPrimaryAttack","GetNextSecondaryAttack","GetItemID",
        "GetWeaponID","GetItemDefinitionIndex","GetDefIndex","GetItem",
        "GetWeaponData","GetCSGOWeaponData","GetType","GetWeaponType",
        "GetPropInt","GetProp","GetPropString","GetPropFloat","GetPropEntity","GetPropVector",
        "GetNetProp","GetNetPropInt","GetNetPropString","GetNetPropEntity",
        "GetIntNet","GetHandleNet","GetEntityNet",
        "GetOwnerIndex","GetPlayerID","GetActiveWeapon","GetActiveWeaponName",
        "GetLocalPlayer","GetTeamNumber","GetHealth","GetSteamID",
    }
    for _, name in ipairs(methods) do
        local r = safe(e, name)
        if r ~= "NO_METHOD" then
            print("    " .. name .. " -> " .. r)
        end
    end

    print("========== PROBE W2 END ==========")
end
callbacks.Register("Draw", "probe_w2_cb", cb)
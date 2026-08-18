-- probe_weapon_owner.lua — find first weapon entity and dump its methods
local function safe(obj, name, ...)
    if not obj then return "NO" end
    local m = obj[name]
    if not m then return "NO_METHOD" end
    local ok, res = pcall(m, obj, ...)
    if not ok then return "ERR:" .. tostring(res):sub(1,40) end
    return "OK:" .. type(res) .. ":" .. tostring(res):sub(1,60)
end

local cb
cb = function()
    callbacks.Unregister("Draw", "probe_weapon_owner_cb")
    print("========== PROBE WEAPON OWNER START ==========")

    -- Find first weapon entity
    local weapon = nil
    local weapon_class = nil
    for i = 0, 420 do
        local ok, e = pcall(function() return entities.GetByIndex(i) end)
        if ok and e then
            local class = safe(e, "GetClass") or ""
            if class:find("^C_Weapon") or class:find("^C_Knife") or class:find("^C_C4") then
                weapon = e
                weapon_class = class
                print("[first weapon] index=" .. i .. " class=" .. class .. " name=" .. safe(e, "GetName"))
                break
            end
        end
    end

    if not weapon then
        print("NO weapon found")
        return
    end

    -- Probe every method
    local method_names = {
        "GetIndex","GetName","GetClass","GetAbsOrigin","IsAlive",
        "GetOwner","GetOwnerEntity","GetOwnerHandle","GetPlayerOwner",
        "GetPlayerOwnerEntity","GetHoldingPlayer","GetOwningPlayer","GetOwnerPlayer",
        "GetEntOwner","GetOwningEntity",
        "GetClip1","GetClip2","GetReserveAmmo","GetAmmo","GetAmmoInClip",
        "GetNextPrimaryAttack","GetNextSecondaryAttack","GetItemID",
        "GetWeaponID","GetItemDefinitionIndex","GetDefIndex","GetItem",
        "GetWeaponData","GetCSGOWeaponData","GetType","GetWeaponType",
        "GetPropInt","GetProp","GetPropString","GetPropFloat","GetPropEntity","GetPropVector",
        "GetNetProp","GetNetPropInt","GetNetPropString","GetNetPropEntity",
        "GetIntNet","GetHandleNet","GetEntityNet",
        -- aimware-priv specific
        "GetWeaponID","GetOwnerIndex","GetPlayerID","GetPlayerID",
        "GetActiveWeapon","GetActiveWeaponName",
    }
    for _, name in ipairs(method_names) do
        local r = safe(weapon, name)
        if r ~= "NO_METHOD" then
            print("  weapon:" .. name .. " -> " .. r)
        end
    end

    -- Iterate metatable if possible
    local mt = getmetatable(weapon)
    print("[weapon mt]")
    if type(mt) == "table" then
        for k, v in pairs(mt) do
            print("  mt." .. tostring(k) .. " = " .. type(v))
        end
    elseif type(mt) == "function" then
        print("  mt is function (can't enumerate)")
    end

    print("========== PROBE WEAPON OWNER END ==========")
end
callbacks.Register("Draw", "probe_weapon_owner_cb", cb)
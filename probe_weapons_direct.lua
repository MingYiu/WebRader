-- probe_weapons_direct.lua — find weapon entities directly and probe them
local function safe(obj, name, ...)
    if not obj then return "NO" end
    local m = obj[name]
    if not m then return "NO_METHOD" end
    local ok, res = pcall(m, obj, ...)
    if not ok then return "ERR" end
    return "OK:" .. type(res) .. ":" .. tostring(res):sub(1,60)
end

local cb
cb = function()
    callbacks.Unregister("Draw", "probe_weapons_direct_cb")
    print("========== PROBE WEAPONS DIRECT START ==========")

    -- Scan ALL entities, find weapon classes
    local weapon_classes = {}
    local weapon_count = 0
    for i = 0, 2048 do
        local ok, e = pcall(function() return entities.GetByIndex(i) end)
        if ok and e then
            local class = safe(e, "GetClass") or ""
            if class:find("^CWeapon") or class:find("Knife") or class:find("Bomb") or class:find("C4") then
                weapon_count = weapon_count + 1
                if weapon_count <= 20 then
                    print(string.format("  i=%d class=%s name=%s",
                        i, class, safe(e, "GetName")))
                end
                weapon_classes[i] = class
            end
        end
    end
    print("  total weapon-like entities: " .. weapon_count)

    -- Pick first CWeapon entity and dump every method
    for i = 0, 2048 do
        local ok, e = pcall(function() return entities.GetByIndex(i) end)
        if ok and e then
            local class = safe(e, "GetClass") or ""
            if class:find("^CWeaponAK47") or class:find("^CWeaponGlock") or class:find("^CWeaponAWP") then
                print("[weapon entity methods] i=" .. i .. " class=" .. class)
                local method_names = {
                    "GetIndex","GetName","GetClass","GetAbsOrigin","IsAlive",
                    "GetOwner","GetOwnerEntity","GetOwnerHandle","GetPlayerOwner",
                    "GetPlayerOwnerEntity","GetHoldingPlayer","GetOwningPlayer",
                    "GetOwnerPlayer","GetEntOwner",
                    "GetClip1","GetClip2","GetReserveAmmo","GetAmmo","GetAmmoInClip",
                    "GetNextPrimaryAttack","GetNextSecondaryAttack","GetItemID",
                    "GetWeaponID","GetItemDefinitionIndex","GetDefIndex",
                    "GetWeaponData","GetCSGOWeaponData",
                    "GetPropInt","GetProp","GetPropString","GetPropFloat",
                }
                for _, name in ipairs(method_names) do
                    local r = safe(e, name)
                    if r ~= "NO_METHOD" then
                        print("    weapon:" .. name .. " -> " .. r)
                    end
                end
                -- Also probe the entity's class hierarchy
                local mt = getmetatable(e)
                print("    weapon mt = " .. type(mt))
                if type(mt) == "table" then
                    for k, v in pairs(mt) do
                        print("      weapon mt." .. tostring(k) .. " = " .. type(v))
                    end
                end
                break
            end
        end
    end

    print("========== PROBE WEAPONS DIRECT END ==========")
end
callbacks.Register("Draw", "probe_weapons_direct_cb", cb)
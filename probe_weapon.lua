-- probe_weapon.lua — figure out why m_hActiveWeapon returns nil
local function dump_weapon(ent, label)
    if not ent then
        print(label .. ": ent=nil")
        return
    end
    local idx = ent:GetIndex() or -1
    print(string.format("==== %s (idx=%d) ====", label, idx))

    -- The handle itself
    local ok, wpn = pcall(function() return ent:GetPropEntity("m_hActiveWeapon") end)
    print("  m_hActiveWeapon: ok=" .. tostring(ok) .. " wpn=" .. tostring(wpn) ..
          " (type=" .. type(wpn) .. ")")
    if wpn then
        pcall(function()
            print("    wpn:GetIndex()=" .. tostring(wpn:GetIndex()))
            print("    wpn:GetClassName()=" .. tostring(wpn:GetClassName()))
            print("    wpn:GetName()=" .. tostring(wpn:GetName()))
            print("    wpn:IsValid()=" .. tostring(wpn:IsValid()))
        end)
        pcall(function() print("    m_iItemDefinitionIndex=" .. tostring(wpn:GetPropInt("m_iItemDefinitionIndex"))) end)
        pcall(function() print("    m_AttributeManager.m_Item.m_iItemDefinitionIndex=" .. tostring(wpn:GetPropInt("m_AttributeManager.m_Item.m_iItemDefinitionIndex"))) end)
        pcall(function() print("    m_iClip1=" .. tostring(wpn:GetPropInt("m_iClip1"))) end)
    end

    -- Try m_MyWeapons (the slot-based bitmask)
    print("  --- m_MyWeapons scan ---")
    local found_in_slots = 0
    for slot = 0, 15 do
        local ok2, we = pcall(function() return ent:GetPropEntity(string.format("m_MyWeapons(%d)", slot)) end)
        if ok2 and we then
            pcall(function()
                local cls = we:GetClassName()
                local i = we:GetIndex() or -1
                if cls and cls ~= "" and cls ~= "weapon_base" then
                    print(string.format("    slot %d: idx=%d class=%s", slot, i, cls))
                    found_in_slots = found_in_slots + 1
                end
            end)
        end
    end
    if found_in_slots == 0 then
        print("    (no weapons found in any slot)")
    end

    -- Try m_hMyWeapons array (CS2 alt)
    print("  --- m_hMyWeapons array scan ---")
    for i = 0, 7 do
        local ok3, we = pcall(function() return ent:GetPropEntity(string.format("m_hMyWeapons.%d", i)) end)
        if ok3 and we then
            pcall(function()
                local cls = we:GetClassName()
                if cls and cls ~= "" and cls ~= "weapon_base" then
                    print(string.format("    arr[%d]: idx=%d class=%s", i, we:GetIndex() or -1, cls))
                end
            end)
        end
    end
end

local cb
cb = function()
    callbacks.Unregister("Draw", "probe_weapon_cb")
    print("========== PROBE WEAPON START ==========")

    -- Local player
    local me = entities.GetLocalPlayer()
    dump_weapon(me, "Local player (me)")

    -- First enemy/any other player
    local found_one = false
    for _, e in ipairs(entities.FindAll("CCSPlayerPawn") or {}) do
        if not found_one and e and e:IsValid() then
            dump_weapon(e, "First CCSPlayerPawn found")
            found_one = true
            break
        end
    end

    -- First C_CSPlayerPawn
    for _, e in ipairs(entities.FindAll("C_CSPlayerPawn") or {}) do
        if not found_one and e and e:IsValid() then
            dump_weapon(e, "First C_CSPlayerPawn found")
            found_one = true
            break
        end
    end

    print("========== PROBE WEAPON END ==========")
end
callbacks.Register("Draw", "probe_weapon_cb", cb)

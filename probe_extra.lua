-- probe_extra.lua — try every weird method name we haven't tried yet
local function safe(obj, name, ...)
    if not obj then return "NO" end
    local m = obj[name]
    if not m then return "NO_METHOD" end
    local ok, res = pcall(m, obj, ...)
    if not ok then return "ERR:" .. tostring(res):sub(1,50) end
    return "OK:" .. type(res) .. ":" .. tostring(res):sub(1,50)
end

local cb
cb = function()
    callbacks.Unregister("Draw", "probe_extra_cb")
    print("========== PROBE EXTRA START ==========")

    local me = entities.GetLocalPlayer()
    -- Every weird prop/weapon/eye-angle/armor guess
    local guesses = {
        "GetBonePosition","GetBoneMatrix","GetBoneName",
        "GetHitboxPosition","GetHitboxBounds","GetHitboxes",
        "GetAimPunch","GetAimPunchAngle","GetPunchAngle","GetPunch","GetPunches","GetShotsFired",
        "GetFlashDuration","GetFlashAlpha","GetFlashMaxAlpha",
        "GetArmorValue","HasArmor","HasHelmet","GetHasHelmet",
        "GetAccount","GetMoney","GetCash","GetScore",
        "GetCompetitiveRanking","GetRank","GetWins","GetMVPs",
        "GetPing","GetLatency","GetLastPlace","GetLastPlaceName",
        "GetCurrentState","GetPlayerState","GetIsScoped","IsScoped",
        "IsDucking","IsDucked","IsCrouched","GetFlags","GetMoveType",
        "GetVelocity","GetAbsVelocity","GetBaseVelocity",
        "GetTickBase","GetNextAttack","GetNextPrimaryAttack",
        "GetFOV","GetDefaultFOV","GetActiveFOV",
        "GetWeaponsCount","GetWeaponCount","GetAmmo",
        "GetClip1","GetClip2","GetReserveAmmo","GetAmmoInClip",
        "GetRenderAngles","GetRenderOrigin","GetModel","GetModelName",
        -- Try CCSGO_ prefixed
        "GetCSGOWeaponData","GetWeaponData","GetItemDefinitionIndex",
        "GetWeaponID","GetWeaponName","GetActiveWeaponID",
        -- aimware common
        "GetPlayerWeapon","GetPlayerWeapons","GetWeaponsInfo","GetWeaponsByType",
        "GetWeaponsByClass","GetWeaponClass","GetWeaponSlot",
        "GetEquipment","GetGrenades","GetPrimaryWeapon","GetSecondaryWeapon",
        -- last hope
        "GetAllWeapons","GetInventoryWeapons","GetLoadout",
        "GetCurrentEquipment","GetWeaponTable",
        -- try entities helper methods
        "GetEntitiesByClass","GetByClass","FindByClass","FindAllByClass",
    }
    for _, name in ipairs(guesses) do
        local r = safe(me, name)
        if r ~= "NO_METHOD" then
            print(string.format("  me:%s -> %s", name, r))
        end
    end

    -- Also try on entities namespace functions
    print("[entities extras]")
    for _, name in ipairs(guesses) do
        local r = safe(entities, name)
        if r ~= "NO_METHOD" then
            print(string.format("  entities:%s -> %s", name, r))
        end
    end

    print("========== PROBE EXTRA END ==========")
end
callbacks.Register("Draw", "probe_extra_cb", cb)
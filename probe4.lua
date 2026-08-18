-- probe4.lua — find a working way to read CS2 pawn origin
-- Must run INSIDE a real CS2 round (with at least 1 other player).

local me = entities.GetLocalPlayer()
if not me then
    print("no local player — start a round first")
    return
end

print("==== Local player ====")
print("  class: " .. tostring(me:GetClass()))
print("  index: " .. tostring(me:GetIndex()))

-- 1) Direct GetAbsOrigin
local ok1, r1 = pcall(function() return me:GetAbsOrigin() end)
print("==== GetAbsOrigin ====")
print("  ok=" .. tostring(ok1) .. " type=" .. type(r1))
if type(r1) == "userdata" then
    print("  x=" .. tostring(r1.x) .. " y=" .. tostring(r1.y) .. " z=" .. tostring(r1.z))
end
if type(r1) == "table" then
    print("  [1]=" .. tostring(r1[1]) .. " [2]=" .. tostring(r1[2]) .. " [3]=" .. tostring(r1[3]))
    for k, v in pairs(r1) do print("  key=" .. tostring(k) .. " v=" .. tostring(v)) end
end

-- 2) GetOrigin (legacy)
local ok2, r2 = pcall(function() return me:GetOrigin() end)
print("==== GetOrigin ====")
print("  ok=" .. tostring(ok2) .. " type=" .. type(r2))
if type(r2) == "userdata" then
    print("  x=" .. tostring(r2.x) .. " y=" .. tostring(r2.y) .. " z=" .. tostring(r2.z))
end

-- 3) GetVecOrigin
local ok3, r3 = pcall(function() return me:GetVecOrigin() end)
print("==== GetVecOrigin ====")
print("  ok=" .. tostring(ok3) .. " type=" .. type(r3))

-- 4) GetPropVector on CGameSceneNode / m_vecOrigin
local tries = {
    {"CGameSceneNode", "m_vecOrigin"},
    {"CGameSceneNode", "m_vecAbsOrigin"},
    {"", "m_vecOrigin"},
    {"", "m_vecAbsOrigin"},
    {"CBaseEntity", "m_vecOrigin"},
    {"CEntityIdentity", "m_vecOrigin"},
}
print("==== GetPropVector tries ====")
for _, t in ipairs(tries) do
    local ok, r = pcall(function() return me:GetPropVector(t[1], t[1] == "" and t[2] or t[2]) end)
    local s = tostring(t[1]) .. " / " .. tostring(t[2])
    if ok and r then
        local x, y, z = "?", "?", "?"
        if type(r) == "userdata" then x, y, z = tostring(r.x), tostring(r.y), tostring(r.z)
        elseif type(r) == "table" then x, y, z = tostring(r[1] or r.x), tostring(r[2] or r.y), tostring(r[3] or r.z) end
        print("  " .. s .. " -> x=" .. x .. " y=" .. y .. " z=" .. z)
    else
        print("  " .. s .. " -> failed: " .. tostring(r))
    end
end

-- 5) SetupBones + GetBonePosition for hips
local ok5, r5 = pcall(function()
    return me:SetupBones()
end)
print("==== SetupBones ====")
print("  ok=" .. tostring(ok5))
if ok5 and r5 then print("  type=" .. type(r5) .. " len=" .. (type(r5)=="table" and #r5 or "?")) end

-- 6) GetBonePosition
local ok6, r6 = pcall(function()
    return me:GetBonePosition(0)
end)
print("==== GetBonePosition(0) ====")
print("  ok=" .. tostring(ok6) .. " type=" .. type(r6))
if type(r6) == "userdata" then print("  x=" .. tostring(r6.x) .. " y=" .. tostring(r6.y) .. " z=" .. tostring(r6.z)) end

-- 7) GetPropInt for "m_iTeamNum" / "m_iHealth" on local
print("==== Local prop sanity ====")
print("  m_iTeamNum = " .. tostring(me:GetPropInt("m_iTeamNum")))
print("  m_iHealth = " .. tostring(me:GetPropInt("m_iHealth")))

-- 8) Engine-level world-to-screen / GetLocalPlayer position
local ok7, r7 = pcall(function() return globals.AbsoluteFrameTime() end)
print("==== engine globals ====")
print("  AbsoluteFrameTime: " .. tostring(r7))

-- 9) What other Get* methods does this entity have?
local mt = getmetatable(me)
if mt then
    local idx = mt.__index
    if type(idx) == "table" then
        local keys = {}
        for k in pairs(idx) do
            if type(k) == "string" and (k:find("Pos") or k:find("Origin") or k:find("Vec") or k:find("Bone") or k:find("Abs") or k:find("Eye")) then
                keys[#keys+1] = k
            end
        end
        table.sort(keys)
        print("==== pos-related methods ====")
        for _, k in ipairs(keys) do print("  " .. k) end
    end
end

print("==== probe4 done ====")
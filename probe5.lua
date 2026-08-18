-- probe5.lua — find out WHY hot-loop GetAbsOrigin returns near-zero values
-- while probe4 directly returns the real ones (-1181, -754, 120).
-- Theory: Aimware Lua 5.1 userdata fields become nil after some pcall/frame boundary.

local me = entities.GetLocalPlayer()
if not me then
    print("no local player — start a round first")
    return
end

print("==== Direct read outside pcall ====")
local o1 = me:GetAbsOrigin()
print("  o1 type=" .. type(o1))
if type(o1) == "userdata" then
    print("  o1.x=" .. tostring(o1.x) .. " o1.y=" .. tostring(o1.y) .. " o1.z=" .. tostring(o1.z))
end

print("==== Read inside single pcall ====")
pcall(function()
    local o = me:GetAbsOrigin()
    if type(o) == "userdata" then
        print("  inside pcall: x=" .. tostring(o.x) .. " y=" .. tostring(o.y) .. " z=" .. tostring(o.z))
    end
end)

print("==== Read inside NESTED pcall (same as hot loop) ====")
pcall(function()
    pcall(function()
        local o = me:GetAbsOrigin()
        if type(o) == "userdata" then
            print("  nested pcall: x=" .. tostring(o.x) .. " y=" .. tostring(o.y) .. " z=" .. tostring(o.z))
        end
    end)
end)

print("==== Read inside pcall wrapped in a function ====")
local function inner()
    local o = me:GetAbsOrigin()
    if type(o) == "userdata" then
        print("  inner fn: x=" .. tostring(o.x) .. " y=" .. tostring(o.y) .. " z=" .. tostring(o.z))
    end
end
pcall(function() inner() end)

print("==== Read inside pcall, after creating local pos table ====")
pcall(function()
    local pos = {x=0,y=0,z=0}
    local o = me:GetAbsOrigin()
    if type(o) == "userdata" then
        pos = {x = o.x or 0, y = o.y or 0, z = o.z or 0}
    end
    print("  pos.x=" .. tostring(pos.x) .. " pos.y=" .. tostring(pos.y) .. " pos.z=" .. tostring(pos.z))
end)

print("==== Read inside pcall, with tostring() on fields ====")
pcall(function()
    local o = me:GetAbsOrigin()
    if type(o) == "userdata" then
        local sx, sy, sz = tostring(o.x), tostring(o.y), tostring(o.z)
        print("  tostring: " .. sx .. ", " .. sy .. ", " .. sz)
    end
end)

print("==== Read + immediate arithmetic (forces number coercion) ====")
pcall(function()
    local o = me:GetAbsOrigin()
    if type(o) == "userdata" then
        local x = o.x + 0  -- forces coercion
        local y = o.y + 0
        local z = o.z + 0
        print("  arithmetic: x=" .. tostring(x) .. " y=" .. tostring(y) .. " z=" .. tostring(z))
        print("  types: x=" .. type(x) .. " y=" .. type(y) .. " z=" .. type(z))
    end
end)

print("==== Bone position via SetupBones-required path ====")
pcall(function()
    local bp = me:GetBonePosition(0)
    if type(bp) == "userdata" then
        print("  bone0: x=" .. tostring(bp.x) .. " y=" .. tostring(bp.y) .. " z=" .. tostring(bp.z))
    end
end)

print("==== Try EntityList (bypasses entity wrapper) ====")
pcall(function()
    local elist = entities.GetEntityByIndex
    if elist then
        local ent = elist(me:GetIndex())
        local o = ent:GetAbsOrigin()
        if type(o) == "userdata" then
            print("  by-index: x=" .. tostring(o.x) .. " y=" .. tostring(o.y) .. " z=" .. tostring(o.z))
        end
    end
end)

print("==== Schedule hot-loop test in 1s ====")
local hot_cb
hot_cb = function()
    callbacks.Unregister("Draw", "probe5_hot")
    print("==== HOT FRAME TEST ====")
    pcall(function()
        local o = me:GetAbsOrigin()
        if type(o) == "userdata" then
            print("  hotframe direct: x=" .. tostring(o.x) .. " y=" .. tostring(o.y) .. " z=" .. tostring(o.z))
        end
    end)
    pcall(function()
        pcall(function()
            local o = me:GetAbsOrigin()
            if type(o) == "userdata" then
                print("  hotframe nested: x=" .. tostring(o.x) .. " y=" .. tostring(o.y) .. " z=" .. tostring(o.z))
            end
        end)
    end)
    for i = 1, 10 do
        pcall(function()
            local o = me:GetAbsOrigin()
            if type(o) == "userdata" then
                local x, y, z = o.x, o.y, o.z
                print(string.format("  loop %d: x=%.2f y=%.2f z=%.2f", i, x or -999, y or -999, z or -999))
            end
        end)
    end
    print("==== probe5 done ====")
end
callbacks.Register("Draw", "probe5_hot", hot_cb)
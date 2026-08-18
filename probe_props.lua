-- probe_props.lua — discover what methods/fields exist on local player
local function dump_methods(obj, label)
    print("==== " .. label .. " ====")
    if not obj then
        print("  nil")
        return
    end
    print("  type=" .. type(obj))
    local mt = getmetatable(obj)
    if not mt then
        print("  no metatable")
        return
    end
    local count = 0
    for k, v in pairs(mt) do
        count = count + 1
        local t = type(v)
        if count <= 60 then
            print(string.format("  [%s] = %s", tostring(k), t))
        end
    end
    print("  total keys: " .. count)
end

local cb
cb = function()
    callbacks.Unregister("Draw", "probe_props_cb")
    print("========== PROBE PROPS START ==========")

    -- 1) global `entities` namespace
    print("---- entities namespace ----")
    for k, v in pairs(entities or {}) do
        print("  entities." .. tostring(k) .. " = " .. type(v))
    end
    local mt = getmetatable(entities or {})
    if mt then
        print("  entities metatable:")
        for k, v in pairs(mt) do
            local t = type(v)
            if t ~= "function" or true then
                print(string.format("    entities:%s = %s", tostring(k), t))
            end
        end
    end

    -- 2) methods on the local player
    local me = entities.GetLocalPlayer()
    dump_methods(me, "Local player methods (via metatable)")

    -- 3) look at globals too
    print("---- global helpers ----")
    for _, name in ipairs({"client","clientstate","entitylist","panorama","ui","materials","render"}) do
        if _G[name] ~= nil then
            print("  _G." .. name .. " exists (type=" .. type(_G[name]) .. ")")
        end
    end

    print("========== PROBE PROPS END ==========")
end
callbacks.Register("Draw", "probe_props_cb", cb)
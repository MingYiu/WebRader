-- probe6.lua — definitive test: does me:GetAbsOrigin() work in hot loop?
-- probe5 confirmed it works at script-load time. Does it still work during gameplay?

local results = {calls = 0, nil_pos = 0, bad_userdata = 0, zero_pos = 0, real_pos = 0}
local samples = {}

local cb
cb = function()
    callbacks.Unregister("Draw", "probe6_cb")
    print("==== probe6 hot-frame test ====")
    local me = entities.GetLocalPlayer()
    if not me then
        print("no me!")
        return
    end
    for i = 1, 30 do
        results.calls = results.calls + 1
        local ok, me_pos = pcall(function() return me:GetAbsOrigin() end)
        if not ok then
            print("  call " .. i .. ": pcall ERROR: " .. tostring(me_pos))
        elseif me_pos == nil then
            results.nil_pos = results.nil_pos + 1
            if #samples < 5 then
                samples[#samples+1] = "  call " .. i .. ": me_pos=nil"
            end
        elseif type(me_pos) ~= "userdata" then
            results.bad_userdata = results.bad_userdata + 1
            if #samples < 5 then
                samples[#samples+1] = "  call " .. i .. ": type=" .. type(me_pos)
            end
        else
            local x, y, z = me_pos.x, me_pos.y, me_pos.z
            if x == 0 and y == 0 then
                results.zero_pos = results.zero_pos + 1
                if #samples < 5 then
                    samples[#samples+1] = "  call " .. i .. ": zero (x=" .. tostring(x) .. ")"
                end
            else
                results.real_pos = results.real_pos + 1
                if #samples < 5 then
                    samples[#samples+1] = string.format("  call %d: x=%.1f y=%.1f z=%.1f", i, x or 0, y or 0, z or 0)
                end
            end
        end
    end
    print(string.format("SUMMARY: %d calls, nil=%d, bad_type=%d, zero=%d, real=%d",
        results.calls, results.nil_pos, results.bad_userdata, results.zero_pos, results.real_pos))
    for _, s in ipairs(samples) do print(s) end

    -- Also: try calling entities.GetLocalPlayer() each call (like aimware_client does)
    print("==== probe6 fresh-fetch test ====")
    for i = 1, 10 do
        local me2 = entities.GetLocalPlayer()
        if not me2 then
            print("  call " .. i .. ": me2=nil")
        else
            local me_pos2 = me2:GetAbsOrigin()
            if me_pos2 and type(me_pos2) == "userdata" then
                local x, y, z = me_pos2.x, me_pos2.y, me_pos2.z
                print(string.format("  call %d: x=%.1f y=%.1f z=%.1f", i, x or -9999, y or -9999, z or -9999))
            else
                print("  call " .. i .. ": me_pos2 invalid (type=" .. type(me_pos2) .. ")")
            end
        end
    end
end
callbacks.Register("Draw", "probe6_cb", cb)
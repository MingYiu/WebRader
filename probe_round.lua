-- Probe round / score / bomb via client.* / engine.* / globals.* only
-- GetPropInt is dead on this build; find alternative API surface.

local function safe(label, fn)
    local ok, val = pcall(fn)
    if ok and val ~= nil then
        local s
        if type(val) == "userdata" then s = "userdata:" .. tostring(val) end
        if not s then s = type(val) .. ":" .. tostring(val) end
        if #s > 80 then s = s:sub(1, 77) .. "..." end
        print(label .. " = OK:" .. s)
    else
        print(label .. " = NO_METHOD")
    end
end

print("========== PROBE ROUND START ==========")

-- 1. globals.*
safe("[globals.GetRoundNumber]", function() return globals.GetRoundNumber and globals.GetRoundNumber() end)
safe("[globals.GetRoundTime]", function() return globals.GetRoundTime and globals.GetRoundTime() end)
safe("[globals.GetBombTime]", function() return globals.GetBombTime and globals.GetBombTime() end)
safe("[globals.GetBombPlantTime]", function() return globals.GetBombPlantTime and globals.GetBombPlantTime() end)

-- 2. client.*
print("--- client.* score/round ---")
local client_fns = {
    "GetRoundInfo", "GetRoundNumber", "GetScore", "GetTeamScore",
    "GetCTScore", "GetTScore", "GetBombStatus", "GetBombSite",
    "GetMatchInfo", "GetMatchmakingScore", "GetGameInfo",
}
for _, fn_name in ipairs(client_fns) do
    safe("[" .. fn_name .. "]", function()
        local fn = client[fn_name]
        if type(fn) == "function" then return fn(client) end
        return nil
    end)
end

-- 3. engine.*
print("--- engine.* round ---")
safe("[engine.GetRoundNumber]", function() return engine.GetRoundNumber and engine.GetRoundNumber() end)

-- 4. ui.*
print("--- ui.* round ---")
safe("[ui.GetRoundInfo]", function() return ui.GetRoundInfo and ui.GetRoundInfo() end)

-- 5. dump globals / client keys (filtered for keywords)
print("--- globals keys with 'round' or 'score' ---")
if globals then
    for k in pairs(getmetatable(globals) or {}) do
        if k:lower():find("round") or k:lower():find("score") or k:lower():find("bomb") then
            print("  globals has: " .. k)
        end
    end
end

print("--- client keys with 'round' or 'score' ---")
if client then
    for k in pairs(getmetatable(client) or {}) do
        if k:lower():find("round") or k:lower():find("score") or k:lower():find("bomb") then
            print("  client has: " .. k)
        end
    end
end

print("--- engine keys with 'round' or 'score' ---")
if engine then
    for k in pairs(getmetatable(engine) or {}) do
        if k:lower():find("round") or k:lower():find("score") or k:lower():find("bomb") then
            print("  engine has: " .. k)
        end
    end
end

print("========== PROBE ROUND END ==========")
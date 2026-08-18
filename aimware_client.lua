    -- ============================================
    -- Web Radar - Aimware Lua Client (UDP Version)
    -- ============================================

    local CONFIG = {
        update_interval = 0.033,  -- ~30 FPS updates for real-time feel
        enabled = true,
        server_ip = "127.0.0.1",
        server_port = 12345,
    }

    -- ========== UDP Client ==========
    local udp_socket = nil
    local udp_init_done = false
    local udp_test_done = false

    local function init_udp()
        if udp_socket then return true end
        
        local ok, sock = pcall(function()
            return network.Socket("UDP")
        end)
        
        if ok and sock then
            udp_socket = sock
            print("[Radar] UDP socket created!")
            return true
        else
            print("[Radar] UDP socket failed: " .. tostring(sock))
            return false
        end
    end

    -- ========== JSON Encoder ==========
    local function escape(s)
        if type(s) ~= "string" then return "" end
        s = string.gsub(s, '\\', '\\\\')
        s = string.gsub(s, '"', '\\"')
        s = string.gsub(s, '\n', '\\n')
        s = string.gsub(s, '\r', '\\r')
        s = string.gsub(s, '\t', '\\t')
        return s
    end

    local function json_encode(v)   
        if v == nil then return "null"
        elseif v == true then return "true"
        elseif v == false then return "false"
        elseif type(v) == "number" then return string.format("%.2f", v)
        elseif type(v) == "string" then return '"' .. escape(v) .. '"'
        elseif type(v) == "table" then
            local is_arr = (#v > 0)
            if is_arr then
                local t = {}
                for i = 1, #v do table.insert(t, json_encode(v[i])) end
                return "[" .. table.concat(t, ",") .. "]"
            else
                local t = {}
                for k, val in pairs(v) do
                    if type(k) == "string" then
                        table.insert(t, '"' .. escape(k) .. '":' .. json_encode(val))
                    end
                end
                return "{" .. table.concat(t, ",") .. "}"
            end
        end
        return "null"
    end

    -- ========== Send Data via UDP ==========
    local last_send_log = 0
    local send_count = 0
    local function send_data(data)
        if not udp_socket then
            if not init_udp() then return false end
        end

        local json_str = json_encode(data)
        local ok, size = pcall(function()
            return udp_socket:SendTo(CONFIG.server_ip, CONFIG.server_port, json_str)
        end)

        -- 若发送失败，销毁旧 socket，下次重建（修复换图后句柄失效）
        if not ok then
            print("[Radar] Socket send failed, resetting: " .. tostring(size))
            udp_socket = nil
            return false
        end

        -- Log every 30 sends (~1 sec at 30fps)
        send_count = send_count + 1
        if send_count - last_send_log >= 30 then
            last_send_log = send_count
            local player_count = data.players and #data.players or 0
            print(string.format("[Radar] Sent #%d: %d players, %d bytes", send_count, player_count, #json_str))
        end

        return ok and size and size > 0
    end

    -- ========== Get Team Scores ==========
    local function get_team_scores()
        local t_score = 0
        local ct_score = 0
        local my_team = 2
        
        -- Get local player team
        local me = entities.GetLocalPlayer()
        if me then
            pcall(function()
                my_team = me:GetPropInt("m_iTeamNum") or 2
            end)
        end
        
        -- Find team entities
        local teams = entities.FindByClass("CCSTeam")
        if teams then
            for _, team in ipairs(teams) do
                if team then
                    pcall(function()
                        local team_num = team:GetPropInt("m_iTeamNum")
                        local score = team:GetPropInt("m_iScore") or 0
                        
                        if team_num == 2 then
                            t_score = score
                        elseif team_num == 3 then
                            ct_score = score
                        end
                    end)
                end
            end
        end
        
        -- Return based on local player's team
        -- team_score = my team's score, enemy_score = enemy team's score
        if my_team == 2 then
            return t_score, ct_score  -- I'm T
        else
            return ct_score, t_score  -- I'm CT
        end
    end

    -- ========== Get Round Info ==========
    local last_cached_round = 0
    local cached_round_time = 115
    local cached_bomb_time = 40
    local cached_bomb_planted = false

    local function get_round_info()
        local round_time = cached_round_time
        local bomb_time = cached_bomb_time
        local bomb_planted = cached_bomb_planted
        local phase = "live"
        local round_number = 1
        
        -- Try to get from game rules
        pcall(function()
            local game_rules = entities.FindByClass("CCSGameRulesProxy")
            if game_rules and game_rules[1] then
                local gr = game_rules[1]
                local warmup = gr:GetPropInt("m_bIsValveDS") or 0
                if warmup == 1 then
                    phase = "warmup"
                end
                
                -- Check if bomb is planted
                bomb_planted = gr:GetPropInt("m_bBombPlanted") == 1
            end
        end)
        
        -- Get round number from CDirector
        pcall(function()
            local cd = entities.FindByClass("CDirector")
            if cd and cd[1] then
                local rn = cd[1]:GetPropInt("m_iRoundNumber")
                if rn and rn > 0 then
                    round_number = rn
                    if rn ~= last_cached_round then
                        last_cached_round = rn
                        cached_round_time = 115  -- Reset timer on new round
                        cached_bomb_time = 40
                        cached_bomb_planted = false
                    end
                end
            end
        end)
        
        -- Update timer (decrement by ~0.5s each frame)
        if not bomb_planted then
            cached_round_time = math.max(0, cached_round_time - 0.5)
            round_time = cached_round_time
        else
            cached_bomb_time = math.max(0, cached_bomb_time - 0.5)
            bomb_time = cached_bomb_time
        end
        
        return round_time, bomb_time, bomb_planted, phase, round_number
    end

    -- ========== Get Player Data ==========
    local function get_player_data(ent, is_local, my_team)
        local pos = {x = 0, y = 0, z = 0}
        local team = 2
        local hp = 100
        local weapon = "Knife"
        local armor = 0
        local is_alive = 1
        local has_bomb = 0
        local player_name = "Player"
        
        pcall(function()
            local o = ent:GetAbsOrigin()
            if o then 
                if type(o) == "userdata" then
                    pos = {x = o.x or 0, y = o.y or 0, z = o.z or 0}
                elseif o[1] then
                    pos = {x = o[1] or 0, y = o[2] or 0, z = o[3] or 0}
                end
            end
        end)
        
        -- CS2: Try multiple ways to get team number
        pcall(function()
            if ent.GetTeamNumber then
                team = ent:GetTeamNumber() or 2
            end
        end)
        
        if team == 2 then
            pcall(function()
                team = ent:GetPropInt("m_iTeamNum") or 2
            end)
        end
        
        if team == 2 then
            pcall(function()
                team = ent:GetPropInt("m_nTeamNum") or 2
            end)
        end
        
        pcall(function()
            hp = ent:GetPropInt("m_iHealth") or 100
        end)
        
        pcall(function()
            armor = ent:GetPropInt("m_ArmorValue") or 0
        end)
        
        pcall(function()
            is_alive = (ent:IsAlive() == true) and 1 or 0
        end)
        
        pcall(function()
            has_bomb = (ent:GetPropInt("m_bHasDefuser") == 1) and 1 or 0
        end)
        
        -- Try to get player name (for CS2, might need controller)
        pcall(function()
            player_name = ent:GetName() or "Player"
        end)
        
        pcall(function()
            local wpn = ent:GetPropEntity("m_hActiveWeapon")
            if wpn then
                local wpn_name = wpn:GetName()
                if wpn_name then 
                    weapon = wpn_name
                end
            end
        end)
        
        return {
            index = ent:GetIndex(),
            name = player_name,
            team = team,
            is_local = is_local and 1 or 0,
            is_team = (team == my_team) and 1 or 0,
            is_alive = is_alive,
            x = pos.x,
            y = pos.y,
            z = pos.z,
            view_x = 0,
            view_y = 0,
            hp = hp,
            armor = armor,
            weapon = weapon,
            has_bomb = has_bomb
        }
    end

    -- ========== Entity Class Discovery ==========
    -- Call this manually in console: radar_discover_entities()
    function radar_discover_entities()
        print("[Radar] Discovering entity classes...")
        
        -- Common player class names to try
        local class_names = {
            "CCSPlayer", "C_CSPlayer", "CSPlayer", "Player",
            "CTFPlayer", "TFPlayer", "TeamFortressPlayer",
            "CBasePlayer", "BasePlayer", "CPlayer", "PlayerEnt"
        }
        
        local found_players = {}
        
        for _, class_name in ipairs(class_names) do
            local entities_list = entities.FindByClass(class_name)
            if entities_list and #entities_list > 0 then
                print("[Radar] Found " .. #entities_list .. " entities with class: " .. class_name)
                for i, ent in ipairs(entities_list) do
                    if ent then
                        local idx = ent:GetIndex()
                        print("  Entity[" .. i .. "]: Index=" .. idx)
                        pcall(function()
                            local alive = ent:IsAlive()
                            print("    IsAlive=" .. tostring(alive))
                        end)
                    end
                end
                found_players[class_name] = entities_list
            end
        end
        
        -- Try wildcard search
        print("[Radar] Trying wildcard search...")
        for _, class_name in ipairs(class_names) do
            local wildcard = class_name .. "*"
            local entities_list = entities.FindByClass(wildcard)
            if entities_list and #entities_list > 0 then
                print("[Radar] Wildcard " .. wildcard .. " found " .. #entities_list .. " entities")
            end
        end
        
    -- Try entities.GetAll() if available
    local getall = entities.GetAll
    if getall then
        print("[Radar] Trying entities.GetAll()...")
        local all_entities = getall()
        if all_entities then
            print("[Radar] GetAll() returned " .. #all_entities .. " entities")
        end
    else
        print("[Radar] GetAll() not available")
    end
        
        -- Try iterating by index using FindByIndex
        print("[Radar] Trying direct index iteration (0-63)...")
        local player_indices = {}
        
        -- Try different ways to get entity by index
        local get_by_index = entities.FindByIndex or entities.GetByIndex or entities.Get
        if get_by_index then
            for i = 0, 63 do
                local ent = get_by_index(i)
                if ent then
                    local alive = pcall_wrap(function() return ent:IsAlive() end)
                    if alive then
                        local name = pcall_wrap(function() return ent:GetName() end)
                        local class = pcall_wrap(function() return ent:GetClass() end)
                        print("  Index[" .. i .. "]: Name=" .. tostring(name) .. ", Class=" .. tostring(class) .. ", Alive=" .. tostring(alive))
                        table.insert(player_indices, {index = i, name = name, class = class, alive = alive})
                    end
                end
            end
            print("[Radar] Found " .. #player_indices .. " alive entities by index")
        else
            print("[Radar] FindByIndex/GetByIndex not available")
        end
        
        print("[Radar] Discovery complete!")
        return found_players, player_indices
    end

    -- Helper function for safe pcall
    function pcall_wrap(fn)
        local ok, result = pcall(fn)
        if ok then return result else return nil end
    end

    -- Auto-discovery on first run (print once)
    local auto_discovery_done = false

    -- ========== Main Update ==========
    local last_time = 0
    local test_time = 0
    local debug_printed = false
    local last_entity_count = -1

    callbacks.Register("Draw", "RadarUpdate", function()
        -- ==========================================
        -- 永不死掉的保护外壳：换图报错不会注销回调
        -- ==========================================
        local ok, err = pcall(function()
            local now = globals.RealTime() or 0

            -- 初始化 UDP (第一次执行时)
            if not udp_init_done then
                udp_init_done = true
                test_time = now + 1
                print("[Radar] Initializing UDP...")
                init_udp()
            end

            -- 发送测试包 (1秒后)
            if udp_socket and not udp_test_done and now > test_time then
                udp_test_done = true
                local test_data = '{"players": [{"name": "TestPlayer"}], "map_name": "test_map"}'
                local sok, size = pcall(function()
                    return udp_socket:SendTo(CONFIG.server_ip, CONFIG.server_port, test_data)
                end)
                if sok and size then
                    print("[Radar] Test packet sent (" .. size .. " bytes)! Check Python console!")
                else
                    print("[Radar] Test send failed: " .. tostring(size))
                end
            end

            if not CONFIG.enabled then return end

            -- 换图安全守卫：Loading/主菜单期间跳过整个 tick
            -- Aimware Lua 没有 IsConnected/IsInGame，仅靠 GetMapName() 判断
            local guard_map = pcall(function() return engine.GetMapName() end) and engine.GetMapName() or nil
            if not guard_map or guard_map == "" then
                return
            end

            -- 节流（带负值修正，防止换图后 CurTime/RealTime 重置导致永远不发送）
            local cur_t = globals.CurTime() or now
            if cur_t < last_time then
                -- 时间倒退（换图重置），强制校准
                last_time = cur_t
            end
            if cur_t - last_time < CONFIG.update_interval then return end
            last_time = cur_t

            local me = entities.GetLocalPlayer()
            if not me then
                return
            end

            -- 即时调试信息（只在首次检测到玩家时打印一次）
            if not debug_printed then
                debug_printed = true
                print("[Radar] Local player detected!")
            end
        
        local my_team = 2
        pcall(function() my_team = me:GetPropInt("m_iTeamNum") or 2 end)
        
        local players = {}
        table.insert(players, get_player_data(me, true, my_team))
        
        -- CS2: Find all players using C_CSPlayerPawn (player pawn with position)
        local all = entities.FindByClass("C_CSPlayerPawn")
        local method_used = "C_CSPlayerPawn"
        
        -- Try alternative CS2 class names
        if not all or #all <= 1 then
            local alt = entities.FindByClass("CCSPlayerPawn")
            if alt and #alt > 1 then
                all = alt
                method_used = "CCSPlayerPawn"
            end
        end
        
        -- Legacy fallback for CS:GO
        if not all or #all <= 1 then
            local legacy = entities.FindByClass("CCSPlayer")
            if legacy and #legacy > 1 then
                all = legacy
                method_used = "CCSPlayer (legacy)"
            end
        end
        
    local entity_count = all and #all or 0
    
    -- Debug output
    if entity_count ~= last_entity_count then
        last_entity_count = entity_count
        if entity_count > 0 then
            print("[Radar] Found " .. entity_count .. " pawns using: " .. method_used)
        end
    end
    
    -- Collect other players (filter out C_CSGO_PreviewPlayer and invalid teams)
    if all then
        local debug_skipped_preview = 0
        local debug_skipped_team = 0
        local debug_skipped_dead = 0
        local debug_skipped_pos = 0
        local debug_added = 0
        local debug_team_samples = {}
        
        for _, p in ipairs(all) do
            if p and p ~= me then
                local alive = false
                pcall(function() alive = p:IsAlive() end)
                
                local class_name = ""
                local team = 0
                
                pcall(function()
                    class_name = p:GetClass() or ""
                end)
                
                -- Try multiple ways to get team number
                pcall(function()
                    if p.GetTeamNumber then
                        team = p:GetTeamNumber() or 0
                    end
                end)
                
                if team == 0 then
                    pcall(function()
                        team = p:GetPropInt("m_iTeamNum") or 0
                    end)
                end
                
                if team == 0 then
                    pcall(function()
                        team = p:GetPropInt("m_nTeamNum") or 0
                    end)
                end
                
                if team == 0 then
                    pcall(function()
                        team = p:GetPropInt("m_iCompetitiveTeamNum") or 0
                    end)
                end
                
                -- Collect unique team values for debug
                local sample_key = class_name .. "=team" .. tostring(team)
                if not debug_team_samples[sample_key] then
                    debug_team_samples[sample_key] = true
                    if #debug_team_samples <= 10 then
                        print("[Radar] Sample: " .. sample_key)
                    end
                end
                
                -- Skip PreviewPlayer entities
                if class_name == "C_CSGO_PreviewPlayer" or class_name == "CCSGO_PreviewPlayer" then
                    debug_skipped_preview = debug_skipped_preview + 1
                elseif team ~= 2 and team ~= 3 then
                    debug_skipped_team = debug_skipped_team + 1
                else
                    -- Additional validation
                    local valid = false
                    local pos = nil
                    
                    pcall(function()
                        pos = p:GetAbsOrigin()
                        if pos then
                            local px, py, pz
                            if type(pos) == "userdata" then
                                px, py, pz = pos.x, pos.y, pos.z
                            elseif pos[1] then
                                px, py, pz = pos[1], pos[2], pos[3]
                            end
                            
                            if px and py and pz then
                                local dist_from_origin = math.sqrt(px*px + py*py + pz*pz)
                                if dist_from_origin > 100 and math.abs(pz) < 10000 then
                                    valid = true
                                end
                            end
                        end
                    end)
                    
                    if not alive then
                        debug_skipped_dead = debug_skipped_dead + 1
                    elseif not valid then
                        debug_skipped_pos = debug_skipped_pos + 1
                    else
                        table.insert(players, get_player_data(p, false, my_team))
                        debug_added = debug_added + 1
                    end
                end
            end
        end
        
        -- Print summary every 60 frames (~2 seconds at 30fps)
        last_debug_counter = (last_debug_counter or 0) + 1
        if last_debug_counter >= 60 then
            last_debug_counter = 0
            print(string.format("[Radar] Filter: total=%d added=%d preview=%d badteam=%d dead=%d badpos=%d",
                #all, debug_added, debug_skipped_preview, debug_skipped_team, debug_skipped_dead, debug_skipped_pos))
        end
    end
    
    local map = "de_dust2"
    pcall(function() map = engine.GetMapName() or "de_dust2" end)
    
    local view_angles = {x = 0, y = 0}
    pcall(function()
        local va = engine.GetViewAngles()
        if va then
            view_angles = {x = va.x or 0, y = va.y or 0}
        end
    end)
    
    -- 获取本地玩家的真实数据用于 local_player
    local local_player_data = {
        x = 0, y = 0, z = 0, 
        view_x = view_angles.x, 
        view_y = view_angles.y
    }
    
    pcall(function()
        local me_pos = me:GetAbsOrigin()
        if me_pos then
            if type(me_pos) == "userdata" then
                local_player_data = {
                    x = me_pos.x or 0, 
                    y = me_pos.y or 0, 
                    z = me_pos.z or 0, 
                    view_x = view_angles.x, 
                    view_y = view_angles.y
                }
            elseif me_pos[1] then
                local_player_data = {
                    x = me_pos[1] or 0, 
                    y = me_pos[2] or 0, 
                    z = me_pos[3] or 0, 
                    view_x = view_angles.x, 
                    view_y = view_angles.y
                }
            end
        end
    end)
    
    -- Get round info (once)
    local round_time, bomb_time, bomb_planted, phase, round_number = get_round_info()
    
    -- Get team scores (once)
    local team_score, enemy_score = get_team_scores()
    
    local data = {
        players = players,
        local_player = local_player_data,
        map_name = map,
        round_time = round_time,
        bomb_time = bomb_time,
        bomb_planted = bomb_planted,
        phase = phase,
        round_number = round_number,
        team_score = team_score,
        enemy_score = enemy_score,
        bomb_position = nil,
        smoke_positions = {},
        bomb_site = nil,
        stats = {
            team_kills = 0, team_deaths = 0,
            self_kills = 0, self_deaths = 0,
            enemy_kills = 0, enemy_deaths = 0,
            mvp_count = 0, player_score = 0
        }
    }
    
    send_data(data)
        end) -- end of pcall body

        if not ok then
            -- 报错被吞掉，但回调不会被注销
            print("[Radar Guard Error]: " .. tostring(err))
        end
end)

    -- ==========================================
-- 换图事件守卫：清空错误缓存、刷新 debug 状态
-- ==========================================
callbacks.Register("FireGameEvent", "RadarGameEvent", function(event)
        local ok, err = pcall(function()
            if not event then return end
            local eok, name = pcall(function() return event:GetName() end)
            if not eok or not name then return end

            if name == "game_newmap" or name == "game_start" or name == "round_start" then
                print("[Radar] Event " .. name .. " - resetting state...")
                -- 重置调试计数器
                last_debug_counter = nil
                debug_printed = nil
                udp_test_done = nil
                test_time = (globals.RealTime() or 0) + 1
                -- 重置节流时间戳（防止换图后 CurTime 重置造成负值卡死）
                last_time = globals.CurTime() or 0
                -- 销毁旧 socket，下次发送时自动重建
                udp_socket = nil
                udp_init_done = false
            end
        end)
        if not ok then
            print("[Radar] Event handler error: " .. tostring(err))
        end
end)

    -- ========== Console Commands ==========
    function radar_toggle()
        CONFIG.enabled = not CONFIG.enabled
        print("[Radar] " .. (CONFIG.enabled and "Enabled" or "Disabled"))
    end

    function radar_status()
        print("========================================")
        print(" Web Radar 状态")
        print("========================================")
        print("  Enabled: " .. (CONFIG.enabled and "Yes" or "No"))
        print("  Update Interval: " .. CONFIG.update_interval .. "s")
        print("  Server: " .. CONFIG.server_ip .. ":" .. CONFIG.server_port)
        print("  UDP: " .. (udp_socket and "Connected" or "Not initialized"))
        local me = entities.GetLocalPlayer()
        print("  Local Player: " .. (me and "Connected" or "Not in game"))
        if me then
            print("  Local Index: " .. me:GetIndex())
        end
        print("========================================")
        print("Commands:")
        print("  radar_toggle()    - Enable/Disable")
        print("  radar_status()    - Show status")
        print("  radar_discover()  - Discover entities")
    end

    function radar_discover()
        radar_discover_entities()
    end

    -- ========== Init ==========
    print("[Radar] Script loaded (UDP mode)")
    print("[Radar] Server: " .. CONFIG.server_ip .. ":" .. CONFIG.server_port)
    print("[Radar] Auto-test will run in 1 second...")

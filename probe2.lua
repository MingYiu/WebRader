-- probe2.lua — minimal size-probe for f:Write
-- We know Stage 6 wrote 12B successfully. We know 104B+ fails. Find the cutoff.

local function safe(name, fn)
    print("==== " .. name .. " ====")
    local ok, err = pcall(fn)
    if not ok then print("  FAIL: " .. tostring(err)) end
end

-- 1) Probe: does the file even open in "wb" mode after a previous write?
safe("open wb / write 'a' / close", function()
    local f = file.Open("radar_packet.txt", "wb")
    if not f then error("open wb failed") end
    local w = f:Write("a")
    print("  wrote 'a' returned: " .. tostring(w))
    f:Close()
end)

-- 2) Try sizes: 12, 50, 100, 150, 200, 300 — all pure ASCII (no binary)
safe("ascii 12B", function()
    local f = file.Open("radar_packet.txt", "wb")
    f:Write("hello world!!")  -- 13 bytes
    f:Close()
end)

safe("ascii 50B", function()
    local f = file.Open("radar_packet.txt", "wb")
    local s = string.rep("A", 50)
    local w = f:Write(s)
    print("  50B write returned: " .. tostring(w))
    f:Close()
end)

safe("ascii 100B", function()
    local f = file.Open("radar_packet.txt", "wb")
    local s = string.rep("B", 100)
    local w = f:Write(s)
    print("  100B write returned: " .. tostring(w))
    f:Close()
end)

safe("ascii 150B", function()
    local f = file.Open("radar_packet.txt", "wb")
    local s = string.rep("C", 150)
    local w = f:Write(s)
    print("  150B write returned: " .. tostring(w))
    f:Close()
end)

safe("ascii 200B", function()
    local f = file.Open("radar_packet.txt", "wb")
    local s = string.rep("D", 200)
    local w = f:Write(s)
    print("  200B write returned: " .. tostring(w))
    f:Close()
end)

safe("ascii 300B", function()
    local f = file.Open("radar_packet.txt", "wb")
    local s = string.rep("E", 300)
    local w = f:Write(s)
    print("  300B write returned: " .. tostring(w))
    f:Close()
end)

-- 3) Try "ab" append mode (write 200B after existing file)
safe("ab 200B", function()
    local f = file.Open("radar_packet.txt", "ab")
    if not f then error("open ab failed") end
    local s = string.rep("X", 200)
    local w = f:Write(s)
    print("  ab 200B write returned: " .. tostring(w))
    f:Close()
end)

-- 4) Try function form with binary (real packet has NUL + high bytes)
safe("func form binary 50B", function()
    local f = file.Open("radar_packet.txt", "wb")
    local s = string.char(0x01, 0x02, 0x03, 0xff, 0xfe, 0x00, 0xaa, 0xbb, 0xcc, string.rep("Z", 41))
    if file.Write and type(file.Write) == "function" then
        local ok_call = file.Write(f, s)
        print("  file.Write(f, binary) ok=" .. tostring(ok_call))
    else
        print("  file.Write function form not available")
    end
    f:Close()
end)

print("==== probe2 done ====")

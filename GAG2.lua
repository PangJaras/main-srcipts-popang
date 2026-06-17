repeat task.wait() until _G.POPANGClient
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer

local GAME_KEY  = "GROWAGARDEN2"
local CFG       = _G.POPANGClient.Games[GAME_KEY]
local AUTO      = CFG.Automatic
local SETTING   = AUTO.Setting

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local HS        = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Backpack  = LocalPlayer:WaitForChild("Backpack")

-- ── Helpers ───────────────────────────────────────────────────
local function setDesc(text)
    if typeof(_G.Horst_SetDescription) == "function" then
        _G.Horst_SetDescription(text)
    end
end

local function accountDone()
    print("[POPANG] เรียก _G.Horst_AccountChangeDone()")
    if typeof(_G.Horst_AccountChangeDone) == "function" then
        _G.Horst_AccountChangeDone()
    end
end

local function matchFilter(filter, name)
    if not filter or #filter == 0 then return true end
    local lname = string.lower(tostring(name))
    for _, v in ipairs(filter) do
        if string.lower(tostring(v)) == lname then return true end
    end
    return false
end

local function postWebhook(url, content)
    if not url or url == "" then return end
    pcall(function()
        HS:PostAsync(url,
            HS:JSONEncode({ content = content }),
            Enum.HttpContentType.ApplicationJson)
    end)
end

-- ── Inventory reader ──────────────────────────────────────────
local function readInventory()
    local seeds, pets = {}, {}
    for _, item in ipairs(Backpack:GetChildren()) do
        local cat = item:GetAttribute("MainCategory")
        local count = item:GetAttribute("Count") or 0

        if cat == "Seed" then
            local name = item:GetAttribute("SeedTool") or item.Name
            if matchFilter(CFG.Seeds, name) then
                table.insert(seeds, { name = name, count = count })
            end

        elseif item:GetAttribute("Pet") then
            local name = item:GetAttribute("Pet") or item.Name
            local uuid = item:GetAttribute("PetId") or ""
            if matchFilter(CFG.Pets, name) then
                table.insert(pets, { name = name, uuid = uuid })
            end
        end
    end

    -- เรียงตามชื่อ
    table.sort(seeds, function(a, b) return a.name < b.name end)
    table.sort(pets,  function(a, b) return a.name < b.name end)
    return seeds, pets
end

-- ── Description builder ───────────────────────────────────────
local function buildDescription(seeds, pets)
    local lines = {}

    table.insert(lines, "🌱 Seeds")
    if #seeds == 0 then
        table.insert(lines, "  (ไม่มี)")
    else
        for _, s in ipairs(seeds) do
            table.insert(lines, ("  • %-24s x%d"):format(s.name, s.count))
        end
    end

    table.insert(lines, "")
    table.insert(lines, "🐾 Pets")
    if #pets == 0 then
        table.insert(lines, "  (ไม่มี)")
    else
        -- กลุ่ม pet ชื่อเดียวกัน
        local grouped = {}
        local order = {}
        for _, p in ipairs(pets) do
            if not grouped[p.name] then
                grouped[p.name] = 0
                table.insert(order, p.name)
            end
            grouped[p.name] = grouped[p.name] + 1
        end
        for _, name in ipairs(order) do
            table.insert(lines, ("  • %-24s x%d"):format(name, grouped[name]))
        end
    end

    return table.concat(lines, "\n")
end

-- ── Auto-send ─────────────────────────────────────────────────
local sentDone = false

local function autoSend(seeds)
    if not SETTING.Enabled then return end
    if sentDone then return end

    -- กรอง seed ที่ต้องส่ง
    local toSend = {}
    for _, s in ipairs(seeds) do
        if matchFilter(SETTING.Seeds, s.name) and s.count > 0 then
            table.insert(toSend, { s.name, s.count })
        end
    end

    if #toSend == 0 then
        -- ไม่มี seed แล้ว → ChangeAccount
        if SETTING.ChangeAccount then
            accountDone()
            sentDone = true
        end
        return
    end

    -- ส่งให้ทุก Receiver
    for _, receiver in ipairs(AUTO.Receiver) do
        if typeof(_G.POPANG_Send) == "function" then
            local ok = _G.POPANG_Send(receiver, toSend)
            print(("[POPANG] send -> %s | ok=%s"):format(receiver, tostring(ok)))
        end
    end

    sentDone = true

    -- ตรวจ seed หลังส่งว่าหมดจริงไหม
    if SETTING.ChangeAccount then
        task.delay(3, function()
            local seedsAfter, _ = readInventory()
            local remaining = 0
            for _, s in ipairs(seedsAfter) do
                if matchFilter(SETTING.Seeds, s.name) then
                    remaining = remaining + s.count
                end
            end
            if remaining == 0 then
                accountDone()
            else
                print(("[POPANG] seed ยังเหลือ %d ชิ้น ยังไม่ accountDone"):format(remaining))
                sentDone = false  -- ลองใหม่รอบหน้า
            end
        end)
    end
end

-- ── Main loop ─────────────────────────────────────────────────
while true do
    local seeds, pets = readInventory()
    local desc        = buildDescription(seeds, pets)

    setDesc(desc)
    print("[POPANG]\n" .. desc)

    postWebhook(CFG.Webhook,
        ("```\n[%s]\n%s\n```"):format(GAME_KEY, desc))

    autoSend(seeds)

    task.wait(5)
end

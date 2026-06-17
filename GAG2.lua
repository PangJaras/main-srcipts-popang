repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until _G.POPANGClient

local GAME_KEY    = "GROWAGARDEN2"
local CFG         = _G.POPANGClient.Games[GAME_KEY]
local AUTO        = CFG.Automatic
local SETTING     = AUTO.Setting

local Players     = game:GetService("Players")
local HS          = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Backpack    = LocalPlayer:WaitForChild("Backpack")
local leaderstats = LocalPlayer:WaitForChild("leaderstats")
local Sheckles    = leaderstats:WaitForChild("Sheckles")

-- ── Format เงิน ───────────────────────────────────────────────
local function fmtMoney(n)
    local tiers = {
        { 1e12, "T" },
        { 1e9,  "B" },
        { 1e6,  "M" },
        { 1e3,  "K" },
    }
    for _, t in ipairs(tiers) do
        if n >= t[1] then
            local val = n / t[1]
            -- 1 decimal เฉพาะตอนที่ไม่ใช่จำนวนเต็ม
            if val < 10 then
                return ("%.1f%s"):format(val, t[2])
            else
                return ("%.0f%s"):format(val, t[2])
            end
        end
    end
    return tostring(n)
end

-- ── Helpers ───────────────────────────────────────────────────
local function setDesc(text)
    if typeof(_G.Horst_SetDescription) == "function" then
        _G.Horst_SetDescription(text)
    end
end

local function accountDone()
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
        local count = item:GetAttribute("Count") or 0
        local cat   = item:GetAttribute("MainCategory")

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

    table.sort(seeds, function(a, b) return a.name < b.name end)
    table.sort(pets,  function(a, b) return a.name < b.name end)
    return seeds, pets
end

-- ── Description builder ───────────────────────────────────────
local function buildDescription(seeds, pets, money)
    local parts = {}

    -- 🍍 Seeds
    local seedParts = {}
    if #seeds == 0 then
        table.insert(seedParts, "ไม่มี")
    else
        for _, s in ipairs(seeds) do
            table.insert(seedParts, ("%s x%d"):format(s.name, s.count))
        end
    end
    table.insert(parts, "🍍Seed: " .. table.concat(seedParts, " , "))

    -- 🦄 Pets
    local petParts = {}
    if #pets == 0 then
        table.insert(petParts, "ไม่มี")
    else
        local grouped, order = {}, {}
        for _, p in ipairs(pets) do
            if not grouped[p.name] then
                grouped[p.name] = 0
                table.insert(order, p.name)
            end
            grouped[p.name] = grouped[p.name] + 1
        end
        for _, name in ipairs(order) do
            table.insert(petParts, ("%s x%d"):format(name, grouped[name]))
        end
    end
    table.insert(parts, "🦄Pet: " .. table.concat(petParts, " , "))

    -- 💸 Money
    table.insert(parts, "💸Money: " .. fmtMoney(money))

    return table.concat(parts, "  ")
end

-- ── Auto-send ─────────────────────────────────────────────────
local sentDone = false

local function autoSend(seeds)
    if not SETTING.Enabled then return end
    if sentDone then return end

    local toSend = {}
    for _, s in ipairs(seeds) do
        if matchFilter(SETTING.Seeds, s.name) and s.count > 0 then
            table.insert(toSend, { s.name, s.count })
        end
    end

    if #toSend == 0 then
        if SETTING.ChangeAccount then
            accountDone()
            sentDone = true
        end
        return
    end

    for _, receiver in ipairs(AUTO.Receiver) do
        if typeof(_G.POPANG_Send) == "function" then
            _G.POPANG_Send(receiver, toSend)
        end
    end

    sentDone = true

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
                sentDone = false
            end
        end)
    end
end

-- ── Main loop ─────────────────────────────────────────────────
while true do
    local seeds, pets = readInventory()
    local money       = Sheckles.Value
    local desc        = buildDescription(seeds, pets, money)

    setDesc(desc)
    postWebhook(CFG.Webhook, ("```\n[%s]\n%s\n```"):format(GAME_KEY, desc))
    autoSend(seeds)

    task.wait(5)
end

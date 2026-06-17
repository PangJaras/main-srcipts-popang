repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until _G.POPANGClient

local GAME_KEY    = "GROWAGARDEN2"
local CFG         = _G.POPANGClient.Games[GAME_KEY]
local AUTO        = CFG.Automatic
local SETTING     = AUTO.Setting

-- ── Services ──────────────────────────────────────────────────
local Players       = game:GetService("Players")
local RS            = game:GetService("ReplicatedStorage")
local HS            = game:GetService("HttpService")
local LocalPlayer   = Players.LocalPlayer
local Backpack      = LocalPlayer:WaitForChild("Backpack")
local leaderstats   = LocalPlayer:WaitForChild("leaderstats")
local Sheckles      = leaderstats:WaitForChild("Sheckles")

-- ── Networking (สำหรับระบบส่งของ) ────────────────────────────
local SharedModules = RS:WaitForChild("SharedModules")
local Networking    = require(SharedModules:WaitForChild("Networking"))

-- ══════════════════════════════════════════════════════════════
--  SEND SYSTEM (จากโค้ดต้นแบบ)
-- ══════════════════════════════════════════════════════════════
local LIMIT         = 20
local SEND_DELAY    = 1.5
local MAX_RETRIES   = 5
local WAIT_BUFFER   = 0.25
local DEFAULT_CAT   = "Seeds"

local CATEGORY_SOURCES = {
    { module = "SeedData",        category = "Seeds",       fields = { "SeedName" } },
    { module = "SprinklerData",   category = "Sprinklers",  fields = { "SprinklerName" } },
    { module = "WateringcanData", category = "WateringCans",fields = { "Name" } },
    { module = "MushroomData",    category = "Mushrooms",   fields = { "Name" } },
    { module = "RaccoonData",     category = "Raccoons",    fields = { "Name" } },
    { module = "GnomeData",       category = "Gnomes",      fields = { "Name" } },
    { module = "SeedPackData",    category = "SeedPacks",   fields = { "PackName" } },
    { module = "PropData",        category = "Props",       fields = { "PropName" } },
}
local CATEGORY_OVERRIDES = {}

local function requireData(name)
    local mod = SharedModules:FindFirstChild(name)
    if mod and mod:IsA("ModuleScript") then
        local ok, data = pcall(require, mod)
        if ok then return data end
    end
    return nil
end

local itemIndex = {}
local function indexData(data, category, fields)
    if typeof(data) ~= "table" then return end
    local list = (typeof(data.Data) == "table") and data.Data or data
    for _, entry in list do
        if typeof(entry) == "table" then
            for _, field in fields do
                local v = entry[field]
                if typeof(v) == "string" and v ~= "" then
                    local k = string.lower(v)
                    if not itemIndex[k] then
                        itemIndex[k] = { category = category, key = v }
                    end
                end
            end
        end
    end
end

for _, src in CATEGORY_SOURCES do
    indexData(requireData(src.module), src.category, src.fields)
end

local function resolveItem(name)
    local k = string.lower(name)
    if CATEGORY_OVERRIDES[k] then return CATEGORY_OVERRIDES[k], name end
    local hit = itemIndex[k]
        or itemIndex[(string.gsub(k, "%s+seed$", ""))]
        or itemIndex[k .. " seed"]
    if hit then return hit.category, hit.key end
    return DEFAULT_CAT, name
end

local function displayItemName(item)
    if item.Category == "Seeds" and not string.match(string.lower(item.ItemKey), "seed$") then
        return item.ItemKey .. " Seed"
    end
    return item.ItemKey
end

local function buildNote(batch)
    local parts = {}
    for _, item in ipairs(batch) do
        table.insert(parts, ("%s %dx"):format(displayItemName(item), item.Count))
    end
    local note = table.concat(parts, ", ")
    if utf8.len(note) and utf8.len(note) > 100 then
        local cut = utf8.offset(note, 101)
        note = cut and string.sub(note, 1, cut - 1) or string.sub(note, 1, 100)
    end
    return note
end

local function buildBatches(resolved, limit)
    local batches, current, currentCount = {}, {}, 0
    for _, it in ipairs(resolved) do
        local remaining = it.Count
        while remaining > 0 do
            if currentCount >= limit then
                table.insert(batches, current)
                current, currentCount = {}, 0
            end
            local take = math.min(limit - currentCount, remaining)
            table.insert(current, { Category = it.Category, ItemKey = it.ItemKey, Count = take })
            currentCount = currentCount + take
            remaining    = remaining - take
        end
    end
    if #current > 0 then table.insert(batches, current) end
    return batches
end

local function parseWait(message)
    if type(message) ~= "string" then return nil end
    local lower = string.lower(message)
    if not (string.find(lower, "wait") or string.find(lower, "cooldown")) then return nil end
    local n = string.match(message, "(%d+%.?%d*)")
    return n and tonumber(n) or nil
end

local function fmtTime(seconds)
    if seconds >= 60 then
        return ("%dm %.1fs"):format(math.floor(seconds / 60), seconds % 60)
    end
    return ("%.2fs"):format(seconds)
end

-- Send(username, { {"SeedName", count}, ... }) → bool
local function Send(username, items)
    local startClock = os.clock()
    local ok1, userId = pcall(function()
        return Networking.Mailbox.LookupPlayer:Fire(username)
    end)
    if not ok1 or type(userId) ~= "number" or userId <= 0 then
        warn("[Mail] lookup failed:", username, userId)
        return false
    end

    local resolved = {}
    for _, pair in ipairs(items) do
        local name  = pair[1]
        local count = tonumber(pair[2]) or 1
        if type(name) == "string" and name ~= "" and count > 0 then
            local category, key = resolveItem(name)
            table.insert(resolved, { Category = category, ItemKey = key, Count = count })
        end
    end
    if #resolved == 0 then warn("[Mail] nothing valid to send") return false end

    local batches    = buildBatches(resolved, LIMIT)
    local allOk      = true
    local sentCount  = 0
    local waitedTotal = 0
    local cooldown   = SEND_DELAY

    for i, batch in ipairs(batches) do
        local note = buildNote(batch)
        local sent = false

        for attempt = 1, MAX_RETRIES + 1 do
            local ok2, success, message = pcall(function()
                return Networking.Mailbox.SendBatch:Fire(userId, batch, note)
            end)
            if ok2 and success then
                sent = true
                break
            end
            local waitFor = parseWait(message)
            if waitFor then
                cooldown = math.max(cooldown, waitFor)
                local sleep = waitFor + WAIT_BUFFER
                task.wait(sleep)
                waitedTotal = waitedTotal + sleep
            else
                break
            end
        end

        if sent then sentCount = sentCount + 1
        else allOk = false end

        if sent and i < #batches then
            task.wait(cooldown)
            waitedTotal = waitedTotal + cooldown
        end
    end

    local elapsed = os.clock() - startClock
    print(("[Mail] done: %d/%d gift(s) | waited %s | total %s")
        :format(sentCount, #batches, fmtTime(waitedTotal), fmtTime(elapsed)))
    return allOk
end

-- expose ให้ใช้จากภายนอกได้
_G.POPANG_Send = Send

-- ══════════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════════
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

local function fmtMoney(n)
    local tiers = {
        { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" },
    }
    for _, t in ipairs(tiers) do
        if n >= t[1] then
            local val = n / t[1]
            return (val < 10 and ("%.1f%s"):format(val, t[2])
                             or  ("%.0f%s"):format(val, t[2]))
        end
    end
    return tostring(n)
end

-- ══════════════════════════════════════════════════════════════
--  INVENTORY
-- ══════════════════════════════════════════════════════════════
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

-- ══════════════════════════════════════════════════════════════
--  DESCRIPTION
-- ══════════════════════════════════════════════════════════════
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

-- ══════════════════════════════════════════════════════════════
--  AUTO-SEND + CHANGE ACCOUNT
-- ══════════════════════════════════════════════════════════════
local sentDone      = false
local changeCalled  = false

local function checkAndChangAccount(seeds)
    if changeCalled then return end
    -- เช็คว่า seed ที่กำหนดใน Setting.Seeds หมดหมดแล้วหรือยัง
    local remaining = 0
    for _, s in ipairs(seeds) do
        if matchFilter(SETTING.Seeds, s.name) then
            remaining = remaining + s.count
        end
    end
    if remaining == 0 then
        changeCalled = true
        print("[POPANG] seed หมดแล้ว → Horst_AccountChangeDone()")
        accountDone()
    end
end

local function autoSend(seeds)
    if not SETTING.Enabled then return end

    -- ── ถ้าส่งครบรอบแล้ว → แค่เช็ค seed เหลือ (ไม่ส่งซ้ำ) ──
    if sentDone then
        if SETTING.ChangeAccount then
            checkAndChangAccount(seeds)
        end
        return
    end

    -- รวม seed ที่ต้องส่ง
    local toSend = {}
    for _, s in ipairs(seeds) do
        if matchFilter(SETTING.Seeds, s.name) and s.count > 0 then
            table.insert(toSend, { s.name, s.count })
        end
    end

    -- ไม่มีอะไรจะส่ง
    if #toSend == 0 then
        if SETTING.ChangeAccount then
            checkAndChangAccount(seeds)
        end
        return
    end

    -- ส่งให้ทุก Receiver
    local allSent = true
    for _, receiver in ipairs(AUTO.Receiver) do
        local ok = Send(receiver, toSend)
        print(("[POPANG] auto-send -> %s | ok=%s"):format(receiver, tostring(ok)))
        if not ok then allSent = false end
    end

    if allSent then
        sentDone = true
        print("[POPANG] ส่งครบแล้ว รอเช็ค seed หลังส่ง...")

        -- รอให้ server ตัด item ออก แล้วค่อยเช็ค
        if SETTING.ChangeAccount then
            task.delay(3, function()
                local seedsAfter, _ = readInventory()
                checkAndChangAccount(seedsAfter)
                -- ถ้ายังมีเหลือ (server ยังไม่ตัด) → เปิดโอกาสลองใหม่
                if not changeCalled then
                    sentDone = false
                end
            end)
        end
    end
end

-- ══════════════════════════════════════════════════════════════
--  MAIN LOOP
-- ══════════════════════════════════════════════════════════════
while true do
    local seeds, pets = readInventory()
    local money       = Sheckles.Value
    local desc        = buildDescription(seeds, pets, money)

    setDesc(desc)
    postWebhook(CFG.Webhook, ("```\n[%s]\n%s\n```"):format(GAME_KEY, desc))
    autoSend(seeds)

    task.wait(5)
end

repeat task.wait() until game:IsLoaded()
repeat task.wait() until _G.Horst_SetDescription

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Data = LocalPlayer:WaitForChild("Data")

local CommF = ReplicatedStorage.Remotes.CommF_
local function Invoke(...)
    return CommF:InvokeServer(...)
end


if not getgenv().POPANGLOG then
    warn("[ERROR] Config not found! Please load config first.")
    return
end

local Config = getgenv().POPANGLOG.AutoFunctions.BF


local function HasItem(itemName)
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    if not Backpack then return false end

    if Backpack:FindFirstChild(itemName) then
        return true
    end

    local Tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if Tool and Tool.Name == itemName then
        return true
    end

    for _, item in pairs(Invoke("getInventory") or {}) do
        if tostring(item.Name) == itemName then
            return true
        end
    end

    return false
end

local function HasAnyFruitInInventory(fruitList)
    local inventory = Invoke("getInventory")
    if not inventory then return false end
    
    for _, item in pairs(inventory) do
        local itemName = tostring(item.Name)
        for _, fruitName in ipairs(fruitList) do
            if itemName == fruitName then
                print("[Fruit Found in Inventory]", itemName)
                return true, itemName
            end
        end
    end
    
    return false
end

local function GetRaceInfo()
    local race = tostring(Data.Race.Value)

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("RaceTransformed") then
        local _, tier = Invoke("UpgradeRace", "Check")
        return string.format("%s V4 [T%s]", race, tostring(tier)), "V4", tier
    end

    if Invoke("Wenlocktoad", "info") == -2 then
        return race .. " [V3]", "V3", 0
    elseif Data.Race:FindFirstChild("Evolved") then
        return race .. " [V2]", "V2", 0
    end

    return race, "V1", 0
end

local function FormatNumber(num)
    num = tonumber(num)
    if not num then return "0" end

    if num >= 1e9 then
        return string.format("%.1fB", num / 1e9):gsub("%.0", "")
    elseif num >= 1e6 then
        return string.format("%.1fM", num / 1e6):gsub("%.0", "")
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3):gsub("%.0", "")
    end

    return tostring(num)
end

local function GetCurrency()
    return tonumber(Data.Fragments.Value), tonumber(Data.Beli.Value)
end

local function HasMelee(meleeName, skipBuy)
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    if not Backpack then return false end

    if Backpack:FindFirstChild(meleeName) then
        return true
    end

    local Tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if Tool and Tool.Name == meleeName then
        return true
    end

    meleeName = meleeName:gsub(" ", "")
    if skipBuy then return false end

    local result
    if meleeName == "DragonClaw" then
        result = Invoke("BlackbeardReward", "DragonClaw", "1")
    else
        result = Invoke("Buy" .. tostring(meleeName), true)
    end

    return result == 1 or result == 2 or false
end

local function GetAwakenedMoves()
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    if not Backpack then return {} end

    local moves = {}

    local function Scan(container)
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool")
                and tool.ToolTip == "Blox Fruit"
                and tool:FindFirstChild("AwakenedMoves") then

                for _, move in ipairs(tool.AwakenedMoves:GetChildren()) do
                    table.insert(moves, move.Name)
                end
            end
        end
    end

    Scan(Backpack)
    if LocalPlayer.Character then
        Scan(LocalPlayer.Character)
    end

    return moves
end

local function GetFruitMastery()
    local fruit = Data.DevilFruit.Value
    if fruit == "" then return 0 end
    
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    if not Backpack then return 0 end
    
    local function ScanMastery(container)
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == "Blox Fruit" then
                local level = tool:FindFirstChild("Level")
                if level and level:IsA("IntValue") then
                    return level.Value
                end
            end
        end
        return 0
    end
    
    local mastery = ScanMastery(Backpack)
    if mastery == 0 and LocalPlayer.Character then
        mastery = ScanMastery(LocalPlayer.Character)
    end
    
    return mastery
end

local function GetFruitInfo()
    local fruit = Data.DevilFruit.Value
    if fruit == "" then return "None", 0 end

    local shortFruit = fruit:match("^([^-]+)") or fruit

    local mastery = GetFruitMastery()
    local awakened = GetAwakenedMoves()
    
    if #awakened > 0 then
        local hasTap = false
        for _, move in ipairs(awakened) do
            if move:upper() == "TAP" then
                hasTap = true
                break
            end
        end
        
        local maxMoves = hasTap and 6 or 5
        
        if #awakened >= maxMoves then
            return string.format("%s [%d] Full Awakened", shortFruit, mastery), #awakened
        else
            return string.format("%s [%d] Awakened %d/%d", shortFruit, mastery, #awakened, maxMoves), #awakened
        end
    end

    return string.format("%s [%d]", shortFruit, mastery), 0
end

local MeleeList = {
    "Superhuman",
    "Death Step",
    "Sharkman Karate",
    "Electric Claw",
    "Dragon Talon",
    "Godhuman",
    "Sanguine Art"
}


local conditionMet = false
local waitTimer = 0

local function IsBlacklisted()
    local blacklist = getgenv().POPANGLOG.AutoFunctions.Blacklist_Users
    for _, username in ipairs(blacklist) do
        if LocalPlayer.Name == username then
            return true
        end
    end
    return false
end

local function CheckMainConditions()
    local mainConfig = Config.MAIN
    

    local currentLevel = tonumber(Data.Level.Value)
    if currentLevel < mainConfig.Level then
        return false
    end
    

    local fragments, beli = GetCurrency()
    if fragments < mainConfig.Fragments then
        return false
    end
    
    -- Lever
    if mainConfig.Lever then
        if not Invoke("CheckTempleDoor") then
            return false
        end
    end
    

    if mainConfig.Lock_Race.Enable then
        local raceText, raceVersion, tier = GetRaceInfo()
        local currentRace = tostring(Data.Race.Value)
        
        if currentRace ~= mainConfig.Lock_Race.Race then
            return false
        end
        
        if mainConfig.Lock_Race.Ability == "V4" and raceVersion ~= "V4" then
            return false
        elseif mainConfig.Lock_Race.Ability == "V3" and (raceVersion ~= "V3" and raceVersion ~= "V4") then
            return false
        elseif mainConfig.Lock_Race.Ability == "V2" and raceVersion == "V1" then
            return false
        end
    end
    

    if mainConfig.Full_Awake_DF then
        local _, awakenedCount = GetFruitInfo()
        if awakenedCount < 5 then
            return false
        end
    end
    

    if mainConfig.SwordSettigs["Farm Mastery Sword"] then
        for _, swordName in ipairs(mainConfig.SwordSettigs["Sword Names"]) do
            if not HasItem(swordName) then
                return false
            end
        end
    end
    
    return true
end

local function CheckConditions()
    if not getgenv().POPANGLOG.AutoFunctions.Enable then
        return false, "Disabled"
    end
    

    if IsBlacklisted() then
        return false, "Blacklisted User"
    end
    

    if Config.Inventory_Fruits.Enable then
        local hasFruit, fruitName = HasAnyFruitInInventory(Config.Inventory_Fruits.Fruits)
        if hasFruit then
            return true, "Inventory_Fruits: " .. fruitName
        end
    end
    

    if Config["Lock Tiers"].Enable then
        local _, raceVersion, tier = GetRaceInfo()
        if raceVersion == "V4" and tier >= Config["Lock Tiers"].Tier then
            return true, "Lock Tiers: V4 T" .. tostring(tier)
        end
    end
    

    local meleeCount = 0
    for _, melee in ipairs(MeleeList) do
        if HasMelee(melee, false) then
            meleeCount += 1
        end
    end
    
    
    if Config.GOD_CDK_MIR_VAL then
        if meleeCount >= 6 and HasItem("Cursed Dual Katana") and 
           HasItem("Mirror Fractal") and HasItem("Valkyrie Helm") and
           CheckMainConditions() then
            return true, "GOD_CDK_MIR_VAL"
        end
    end
    
    if Config.GOD_MIR_VAL then
        if meleeCount >= 6 and HasItem("Mirror Fractal") and 
           HasItem("Valkyrie Helm") and CheckMainConditions() then
            return true, "GOD_MIR_VAL"
        end
    end
    
    if Config.GOD_SA then
        if meleeCount >= 6 and HasItem("Shark Anchor") and CheckMainConditions() then
            return true, "GOD_SA"
        end
    end
    
    if Config.GOD_CDK then
        if meleeCount >= 6 and HasItem("Cursed Dual Katana") and CheckMainConditions() then
            return true, "GOD_CDK"
        end
    end
    
    if Config.GOD then
        if meleeCount >= 6 and CheckMainConditions() then
            return true, "GOD"
        end
    end
    
    if Config.PASS then
        if CheckMainConditions() then
            return true, "PASS"
        end
    end
    
    return false, "No conditions met"
end


local function UpdateStatus()
    local meleeCount = 0
    for _, melee in ipairs(MeleeList) do
        if HasMelee(melee, false) then
            meleeCount += 1
        end
    end

    local fragments, beli = GetCurrency()
    
    -- ตรวจสอบ special items
    local specialItems = {}
    if HasItem("Cursed Dual Katana") then
        table.insert(specialItems, "⚔️ CDK")
    end
    if HasItem("Shark Anchor") then
        table.insert(specialItems, "⚓️ SA")
    end
    
    if Config.Inventory_Fruits.Enable then
        local inventory = Invoke("getInventory")
        if inventory then
            local foundFruits = {}
            for _, item in pairs(inventory) do
                local itemName = tostring(item.Name)
                for _, fruitName in ipairs(Config.Inventory_Fruits.Fruits) do
                    if itemName == fruitName then
                        local shortName = fruitName:match("^([^-]+)")
                        table.insert(foundFruits, shortName)
                        break
                    end
                end
            end
            
            if #foundFruits > 0 then
                table.insert(specialItems, "📦️Inv: " .. table.concat(foundFruits, "/"))
            end
        end
    end
    
    local itemsText = #specialItems > 0 and (table.concat(specialItems, ",") .. ",") or ""
    
    local raceText = GetRaceInfo()
    local fruitText = GetFruitInfo()

    local description = string.format(
        "👊🏻Melee [%d/%d], B:%s, F:%s, %s, MIR%s, VAL%s, LV%s, %s Lv.%s, %s",
        meleeCount,
        #MeleeList,
        FormatNumber(beli),
        FormatNumber(fragments),
        raceText,
        HasItem("Mirror Fractal") and "✅" or "❌",
        HasItem("Valkyrie Helm") and "✅" or "❌",
        Invoke("CheckTempleDoor") and "✅" or "❌",
        itemsText,
        tostring(Data.Level.Value),
        fruitText
    )

    pcall(function()
        _G.Horst_SetDescription(description)
    end)
    
    print("[Status Updated]", os.date("%X"))
    

    local passed, reason = CheckConditions()
    
    if passed then
        if not conditionMet then
            conditionMet = true
            waitTimer = 0
            print(string.format("[Conditions Met: %s] Waiting 15 seconds before calling AccountChangeDone...", reason))
        end
        
        waitTimer = waitTimer + 10
        
        if waitTimer >= 15 then
            print(string.format("[Calling] _G.Horst_AccountChangeDone() - Reason: %s", reason))
            pcall(function()
                _G.Horst_AccountChangeDone()
            end)
            task.wait(60)
            conditionMet = false
            waitTimer = 0
        end
    else
        if conditionMet then
            print(string.format("[Conditions No Longer Met] Reset timer - Reason: %s", reason))
        end
        conditionMet = false
        waitTimer = 0
    end
end


print("[Script Started] Config loaded successfully!")

while true do
    local success, err = pcall(UpdateStatus)
    if not success then
        warn("[Error in UpdateStatus]:", err)
        task.wait(5)
    end
    task.wait(10)
end

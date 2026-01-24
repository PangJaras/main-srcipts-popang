-- ตรวจสอบว่ามี Config หรือยัง ถ้าไม่มีให้แจ้งเตือน
if not getgenv().PoPang7mConfig then
    warn("ERROR: PoPang7mConfig not found!")
    warn("Please load the config first before running this script")
    return
end

local Config = getgenv().PoPang7mConfig

repeat task.wait() until game:IsLoaded()
warn("Script Loaded!")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local CommF = ReplicatedStorage.Remotes.CommF_

getgenv().LOADED = true
warn("[", os.date("%H:%M:%S"), "] LOADED = true")

local THIRD_SEA_PLACEIDS = {
    [7449423635] = true,
    [100117331123089] = true
}

local TWEEN_SPEED = 300

local SHAFI_CFRAME = CFrame.new(
    -16516.078125, 23.594921112060547, -189.36460876464844
)

-- ตั้งค่า path สำหรับเก็บข้อมูล
local FOLDER_NAME = "SanguineArtData"
local FILE_NAME = LocalPlayer.Name .. ".json"

-- ================= UI FUNCTIONS =================
local currentStatusUI = nil

local function createStatusUI(statusText, debugInfo)
    -- ลบ UI เก่า
    if currentStatusUI then
        currentStatusUI:Destroy()
    end
    
    local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    gui.Name = "SanguineArtStatusUI"
    gui.ResetOnSpawn = false
    currentStatusUI = gui

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 280, 0, debugInfo and 150 or 90)
    frame.Position = UDim2.new(0.5, -140, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "SANGUINE ART SCRIPT"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.new(1, 1, 1)

    local statusLabel = Instance.new("TextLabel", frame)
    statusLabel.Position = UDim2.new(0, 0, 0, 35)
    statusLabel.Size = UDim2.new(1, 0, 0, 40)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = statusText
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 18
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 153)
    statusLabel.Name = "StatusLabel"
    
    -- ถ้ามี debug info ให้แสดง
    if debugInfo then
        local debugFrame = Instance.new("Frame", frame)
        debugFrame.Position = UDim2.new(0, 5, 0, 80)
        debugFrame.Size = UDim2.new(1, -10, 0, 65)
        debugFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        debugFrame.BackgroundTransparency = 0.3
        debugFrame.Name = "DebugFrame"
        
        local debugCorner = Instance.new("UICorner", debugFrame)
        debugCorner.CornerRadius = UDim.new(0, 4)
        
        local debugTitle = Instance.new("TextLabel", debugFrame)
        debugTitle.Size = UDim2.new(1, 0, 0, 18)
        debugTitle.BackgroundTransparency = 1
        debugTitle.Text = "DEBUG INFO"
        debugTitle.Font = Enum.Font.GothamBold
        debugTitle.TextSize = 10
        debugTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
        debugTitle.TextYAlignment = Enum.TextYAlignment.Top
        
        local debugLabel = Instance.new("TextLabel", debugFrame)
        debugLabel.Size = UDim2.new(1, -10, 1, -20)
        debugLabel.Position = UDim2.new(0, 5, 0, 18)
        debugLabel.BackgroundTransparency = 1
        debugLabel.Text = debugInfo
        debugLabel.Font = Enum.Font.Code
        debugLabel.TextSize = 12
        debugLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        debugLabel.TextXAlignment = Enum.TextXAlignment.Left
        debugLabel.TextYAlignment = Enum.TextYAlignment.Top
        debugLabel.Name = "DebugLabel"
    end
    
    return gui
end

local function updateStatusUI(newText, debugText)
    if currentStatusUI then
        local frame = currentStatusUI:FindFirstChild("Frame")
        if frame then
            local statusLabel = frame:FindFirstChild("StatusLabel")
            if statusLabel then
                statusLabel.Text = newText
            end
            
            if debugText then
                local debugFrame = frame:FindFirstChild("DebugFrame")
                if debugFrame then
                    local debugLabel = debugFrame:FindFirstChild("DebugLabel")
                    if debugLabel then
                        debugLabel.Text = debugText
                    end
                end
            end
        end
    end
end

local function showNotification(msg, duration)
    local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    gui.Name = "NotificationUI"

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 260, 0, 50)
    frame.Position = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local text = Instance.new("TextLabel", frame)
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = msg
    text.Font = Enum.Font.GothamBold
    text.TextSize = 16
    text.TextColor3 = Color3.new(1, 1, 1)

    frame:TweenPosition(UDim2.new(1, -270, 1, -60), "Out", "Quad", 0.3, true)

    task.delay(duration or 3, function()
        frame:TweenPosition(UDim2.new(1, 0, 1, 0), "In", "Quad", 0.3, true)
        task.delay(0.3, function() gui:Destroy() end)
    end)
end

-- สร้าง folder ถ้ายังไม่มี
local function CreateFolder()
    if not isfolder(FOLDER_NAME) then
        makefolder(FOLDER_NAME)
        warn("Created folder:", FOLDER_NAME)
    end
end

-- อ่านข้อมูลจากไฟล์
local function LoadPlayerData()
    CreateFolder()
    local filePath = FOLDER_NAME .. "/" .. FILE_NAME
    
    if isfile(filePath) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(filePath))
        end)
        
        if success and data then
            warn("Loaded data for:", LocalPlayer.Name)
            return data
        else
            warn("Failed to load data, using default")
        end
    else
        warn("No existing data file for:", LocalPlayer.Name)
    end
    
    -- ค่า default
    return {
        Username = LocalPlayer.Name,
        HasPurchased = false,
        HasHopped = false,
        LastUpdate = os.time()
    }
end

-- บันทึกข้อมูลลงไฟล์
local function SavePlayerData(data)
    CreateFolder()
    local filePath = FOLDER_NAME .. "/" .. FILE_NAME
    
    data.LastUpdate = os.time()
    
    local success = pcall(function()
        writefile(filePath, HttpService:JSONEncode(data))
    end)
    
    if success then
        warn("Saved data for:", LocalPlayer.Name)
    else
        warn("Failed to save data for:", LocalPlayer.Name)
    end
end

-- โหลดข้อมูลผู้เล่น
local PlayerData = LoadPlayerData()

-- ฟังก์ชันนับ Leviathan Heart
local function GetLeviathanHeartCount()
    local count = 0
    pcall(function()
        for _, item in next, CommF:InvokeServer("getInventory") do
            if item.Type == "Material" and item.Name == "Leviathan Heart" then
                count += item.Count or 1
            end
        end
    end)
    return count
end

-- ฟังก์ชันเช็คว่าพร้อมซื้อ Sanguine Art หรือยัง
local function CanBuySanguineArt()
    local response1, response2
    local maxRetries = 5
    local retryDelay = 1
    
    -- พยายามเรียก response1 จนกว่าจะได้ค่า
    for i = 1, maxRetries do
        local success = pcall(function()
            response1 = CommF:InvokeServer("BuySanguineArt", true)
        end)
        
        if success and response1 ~= nil then
            break
        end
        
        warn("Retry getting response1 (", i, "/", maxRetries, ")")
        task.wait(retryDelay)
    end
    
    -- พยายามเรียก response2 จนกว่าจะได้ค่า
    for i = 1, maxRetries do
        local success = pcall(function()
            response2 = CommF:InvokeServer("BuySanguineArt", true)
        end)
        
        if success and response2 ~= nil then
            break
        end
        
        warn("Retry getting response2 (", i, "/", maxRetries, ")")
        task.wait(retryDelay)
    end
    
    warn("BuySanguineArt Response 1:", response1)
    warn("BuySanguineArt Response 2:", response2)
    
    -- เช็คว่าได้ response กลับมาหรือไม่
    if response1 == nil or response2 == nil then
        warn("WARNING: Failed to get response from BuySanguineArt!")
        warn("Hopping server due to failed responses...")
        showNotification("Failed to get response! Hopping server...", 3)
        task.wait(3)
        HopServer()
        return false, nil
    end
    
    -- ถ้าทั้ง 2 response เป็น 0 แสดงว่าแลกแล้วพร้อมซื้อ
    return response1 == 0 and response2 == 0, response1
end

local function IsInThirdSea()
    return THIRD_SEA_PLACEIDS[game.PlaceId] == true
end

local function FlyUp(height)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    local currentPos = hrp.Position
    hrp.CFrame = CFrame.new(currentPos.X, height or 120, currentPos.Z)
    task.wait(0.5)
end

local function TweenTo(cf)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    local bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
    bodyVel.Velocity = Vector3.new(0, 0, 0)
    bodyVel.Parent = hrp
    
    local dist = (hrp.Position - cf.Position).Magnitude
    local time = dist / TWEEN_SPEED

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(time, Enum.EasingStyle.Linear),
        {CFrame = cf}
    )
    tween:Play()
    tween.Completed:Wait()
    
    bodyVel:Destroy()
end

-- ฟังก์ชันโหลด loadstring
local function ExecuteLoadString(url)
    local success, result = pcall(function()
        if url and url ~= "" then
            local code = game:HttpGet(url)
            return loadstring(code)()
        end
    end)
    
    if not success then
        warn("LoadString execution failed:", result)
        showNotification("LoadString failed: " .. tostring(result), 5)
    end
    
    return success
end

-- ฟังก์ชัน Hop Server
function HopServer()
    warn("Hopping to another server...")
    showNotification("Hopping to another server...", 3)
    
    -- บันทึกว่า hop แล้ว
    PlayerData.HasHopped = true
    SavePlayerData(PlayerData)
    
    task.wait(1)
    
    local success, result = pcall(function()
        local servers = {}
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local data = HttpService:JsonDecode(req)
        
        if data and data.data then
            for _, server in pairs(data.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    table.insert(servers, server.id)
                end
            end
        end
        
        if #servers > 0 then
            local randomServer = servers[math.random(1, #servers)]
            TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, LocalPlayer)
        else
            -- ถ้าไม่มี server ให้ rejoin
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end)
    
    if not success then
        warn("Hop failed, rejoining instead:", result)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end

task.spawn(function()
    warn("Selecting team:", Config.Team)

    repeat
        task.wait(0.5)
        pcall(function()
            CommF:InvokeServer("SetTeam", Config.Team)
        end)
    until LocalPlayer.Character

    warn("Team assembled!")
end)

repeat task.wait() until LocalPlayer.Character

task.spawn(function()
    -- แสดงข้อมูลที่โหลดมา
    warn("=== Player Data ===")
    warn("Username:", PlayerData.Username)
    warn("Has Purchased:", PlayerData.HasPurchased)
    warn("Has Hopped:", PlayerData.HasHopped)
    warn("==================")
    
    -- เช็คเงื่อนไขเพื่อเลือก loadstring
    warn("Checking conditions for loadstring selection...")
    
    local shouldBuy, response = CanBuySanguineArt()
    local heartCount = GetLeviathanHeartCount()
    
    warn("Response:", response)
    warn("Leviathan Heart Count:", heartCount)
    
    local selectedLoadString
    local currentMode = ""
    
    -- เช็คว่าซื้อหมัดไปแล้วและ hop แล้วหรือยัง
    if PlayerData.HasPurchased and PlayerData.HasHopped then
        -- ถ้าซื้อไปแล้วและ hop แล้ว ให้ใช้ LoadString3
        warn("Already purchased and hopped! Using LoadString3")
        currentMode = "LoadString3"
        selectedLoadString = Config.LoadString3
        
        -- สร้าง UI สำหรับ Farm Mastery (ไม่มี debug)
        createStatusUI("Status: Farm Mastery", nil)
        
        if selectedLoadString and selectedLoadString ~= "" then
            warn("Executing LoadString3...")
            showNotification("Starting Farm Mastery...", 3)
            ExecuteLoadString(selectedLoadString)
        else
            warn("LoadString3 is empty or not configured")
            showNotification("LoadString3 not configured!", 3)
        end
        
        warn("Script completed - Sanguine Art process finished")
        return
    elseif response == 1 then
        -- ถ้า response = 1 แสดงว่าซื้อไปแล้ว
        warn("Sanguine Art already purchased!")
        
        if not PlayerData.HasPurchased then
            PlayerData.HasPurchased = true
            SavePlayerData(PlayerData)
        end
        
        -- ถ้ายังไม่ได้ hop ให้ hop
        if not PlayerData.HasHopped then
            warn("Need to hop server first...")
            showNotification("Purchased! Hopping server...", 3)
            task.wait(2)
            HopServer()
            return
        else
            -- ถ้า hop แล้ว ให้รัน LoadString3
            currentMode = "LoadString3"
            selectedLoadString = Config.LoadString3
            
            -- สร้าง UI สำหรับ Farm Mastery (ไม่มี debug)
            createStatusUI("Status: Farm Mastery", nil)
            
            if selectedLoadString and selectedLoadString ~= "" then
                warn("Executing LoadString3...")
                showNotification("Starting Farm Mastery...", 3)
                ExecuteLoadString(selectedLoadString)
            else
                warn("LoadString3 is empty or not configured")
                showNotification("LoadString3 not configured!", 3)
            end
            
            warn("Script completed - Sanguine Art already owned")
            return
        end
    elseif response == 0 and heartCount > 0 then
        -- ถ้า response เป็น 0 และยังมี Leviathan Heart ให้ใช้ loadstring2
        warn("Condition met: Using LoadString2")
        currentMode = "LoadString2"
        selectedLoadString = Config.LoadString2
        
        -- สร้าง UI สำหรับ Buy SanguineArt พร้อม debug
        local debugInfo = string.format("Response1: %s\nResponse2: %s\nHearts: %d", 
            tostring(response), tostring(response), heartCount)
        createStatusUI("Status: Buy SanguineArt", debugInfo)
        
        if selectedLoadString and selectedLoadString ~= "" then
            warn("Executing LoadString2...")
            showNotification("Starting Buy SanguineArt...", 3)
            ExecuteLoadString(selectedLoadString)
        else
            warn("LoadString2 is empty or not configured")
            showNotification("LoadString2 not configured!", 3)
        end
    else
        -- ถ้า response ไม่ใช่ 0 หรืออื่นๆ ให้ใช้ loadstring1
        warn("Condition met: Using LoadString1")
        currentMode = "LoadString1"
        selectedLoadString = Config.LoadString1
        
        -- สร้าง UI สำหรับ Farm Material พร้อม debug
        local debugInfo = string.format("Response1: %s\nResponse2: %s\nHearts: %d", 
            tostring(response), tostring(response), heartCount)
        createStatusUI("Status: Farm Material", debugInfo)
        
        if selectedLoadString and selectedLoadString ~= "" then
            warn("Executing LoadString1...")
            showNotification("Starting Farm Material...", 3)
            ExecuteLoadString(selectedLoadString)
        else
            warn("LoadString1 is empty or not configured")
            showNotification("LoadString1 not configured!", 3)
        end
    end
    
    -- รอให้ loadstring ทำงานเสร็จก่อนเริ่ม logic หลัก
    task.wait(2)
    
    -- เช็คว่าพร้อมซื้อ Sanguine Art หรือยัง
    warn("Checking if ready to buy Sanguine Art...")
    
    while true do
        local canBuy, currentResponse = CanBuySanguineArt()
        
        -- อัพเดท debug info
        if currentMode == "LoadString1" or currentMode == "LoadString2" then
            local heartCount = GetLeviathanHeartCount()
            local debugInfo = string.format("Response1: %s\nResponse2: %s\nHearts: %d", 
                tostring(currentResponse), tostring(currentResponse), heartCount)
            updateStatusUI("Status: " .. (currentMode == "LoadString1" and "Farm Material" or "Buy SanguineArt"), debugInfo)
        end
        
        if canBuy then
            warn("Ready to buy Sanguine Art! Starting main task...")
            showNotification("Ready to buy! Starting...", 3)
            break
        else
            warn("Not ready yet. Waiting 15 seconds...")
            task.wait(15)
        end
    end
    
    -- เริ่มทำงานหลักเมื่อพร้อมซื้อแล้ว
    if not IsInThirdSea() then
        warn("Traveling to Third Sea...")
        showNotification("Traveling to Third Sea...", 3)
        updateStatusUI("Status: Traveling to Sea 3", nil)
        CommF:InvokeServer("TravelZou")
        task.wait(15)
    end

    repeat task.wait(1) until IsInThirdSea()
    warn("Now in Third Sea")
    showNotification("Arrived at Third Sea!", 3)

    warn("Flying up...")
    updateStatusUI("Status: Flying Up", nil)
    FlyUp(120)

    task.wait(1)

    warn("Tweening to Shafi...")
    updateStatusUI("Status: Going to Shafi", nil)
    showNotification("Going to Shafi...", 3)
    TweenTo(SHAFI_CFRAME)

    task.wait(1)

    warn("Start buying Sanguine Art...")
    updateStatusUI("Status: Buying Sanguine Art", nil)
    showNotification("Buying Sanguine Art...", 3)
    
    while true do
        local result = CommF:InvokeServer("BuySanguineArt")
        warn("Buy Result:", result)

        if result == 1 or result == 2 then
            warn("Sanguine Art acquired!")
            showNotification("Sanguine Art Acquired!", 5)
            updateStatusUI("Status: Purchase Complete!", nil)
            
            -- บันทึกว่าซื้อแล้ว
            PlayerData.HasPurchased = true
            SavePlayerData(PlayerData)
            
            -- ถ้า result เป็น 1 และยังไม่เคย hop ให้ hop server
            if result == 1 and not PlayerData.HasHopped then
                warn("Purchase successful! Hopping server to run LoadString3...")
                showNotification("Hopping server for Mastery...", 5)
                task.wait(2)
                HopServer()
            end
            
            break
        end

        task.wait(3)
    end
end)

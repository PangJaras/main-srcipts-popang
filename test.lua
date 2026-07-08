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
local LogService = game:GetService("LogService")

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

-- ตั้งค่า Python Server Hop API
local PYTHON_API = "http://127.0.0.1:5000"
local HOP_TIMEOUT = 5

-- ================= UI FUNCTIONS =================
local currentStatusUI = nil

local function createStatusUI(statusText, debugInfo)
    if currentStatusUI then
        currentStatusUI:Destroy()
    end
    
    local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    gui.Name = "SanguineArtStatusUI"
    gui.ResetOnSpawn = false
    currentStatusUI = gui

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 280, 0, debugInfo and 150 or 90)
    frame.Position = UDim2.new(1, -290, 1, debugInfo and -160 or -100)
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
    statusLabel.TextWrapped = true
    
    if debugInfo then
        local debugFrame = Instance.new("Frame", frame)
        debugFrame.Position = UDim2.new(0, 5, 0, 80)
        debugFrame.Size = UDim2.new(1, -10, 0, 65)
        debugFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        debugFrame.BackgroundTransparency = 0.3
        debugFrame.Name = "DebugFrame"
        debugFrame.ClipsDescendants = true
        
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
        debugLabel.TextWrapped = true
        debugLabel.ClipsDescendants = true
    end
    
    return gui
end

local function updateStatusUI(newText, debugText)
    if not newText then return end
    
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
        local inventory = CommF:InvokeServer("getInventory")
        if inventory then
            for _, item in pairs(inventory) do
                if item.Type == "Material" and item.Name == "Leviathan Heart" then
                    count = count + (item.Count or 1)
                end
            end
        end
    end)
    return count
end

-- ฟังก์ชันเช็คว่ามี Sanguine Art ใน Backpack หรือไม่
local function HasSanguineArtInBackpack()
    local hasArt = false
    
    pcall(function()
        local backpack = LocalPlayer.Backpack
        if backpack and backpack:FindFirstChild("Sanguine Art") then
            hasArt = true
        end
        
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Sanguine Art") then
            hasArt = true
        end
    end)
    
    warn("Has Sanguine Art in Backpack/Character:", hasArt)
    return hasArt
end

-- ================= SERVER HOP (Python-based) =================

-- ขอ server จาก Python API โดยส่ง username และ placeId ปัจจุบันไปด้วย
local function GetServerFromPython()
    local ok, result = pcall(function()
        local url = PYTHON_API .. "/getserver?username=" .. LocalPlayer.Name .. "&placeId=" .. tostring(game.PlaceId)
        local res = game:HttpGet(url)
        return HttpService:JSONDecode(res)
    end)
    
    if not ok then
        warn("[HOP] Failed to contact Python API:", result)
        return nil
    end
    
    if not result.success then
        warn("[HOP] Python API:", result.error)
        return nil
    end
    
    return result
end

-- ฟังก์ชัน Hop Server (ขอ server จาก Python แล้ว teleport + verify ว่า JobId เปลี่ยนจริง)
function HopServer()
    warn("[HOP] Hopping to another server (via Python)...")
    showNotification("Hopping to another server...", 3)
    updateStatusUI("Status: Hopping Server...", nil)
    
    -- บันทึกว่า hop แล้ว
    PlayerData.HasHopped = true
    SavePlayerData(PlayerData)
    
    local originalJobId = game.JobId
    warn("[HOP] Current JobId:", originalJobId, "| PlaceId:", game.PlaceId)
    
    while true do
        warn("[HOP] [", LocalPlayer.Name, "] Requesting server from Python...")
        
        local result = nil
        while not result do
            result = GetServerFromPython()
            if not result then
                warn("[HOP] No server available, retrying in 3 sec...")
                updateStatusUI("Status: Waiting for server...", nil)
                task.wait(3)
            end
        end
        
        local serverId = result.server_id
        warn("[HOP] Got JobId:", serverId)
        warn("[HOP] Players:", result.playing .. "/" .. result.max_players)
        warn("[HOP] Queue remaining:", result.queue_remaining)
        
        updateStatusUI("Status: Teleporting...", nil)
        
        local hopOk, hopErr = pcall(function()
            ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", serverId)
        end)
        
        if not hopOk then
            warn("[HOP] __ServerBrowser invoke failed:", hopErr)
            warn("[HOP] Falling back to TeleportToPlaceInstance...")
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
            end)
        end
        
        -- รอแล้วเช็คว่า JobId เปลี่ยนไหม
        local startTime = tick()
        local hopped = false
        
        while tick() - startTime < HOP_TIMEOUT do
            task.wait(0.5)
            if game.JobId ~= originalJobId then
                hopped = true
                break
            end
        end
        
        if hopped then
            warn("[HOP] SUCCESS! JobId changed:", originalJobId, "->", game.JobId)
            break
        else
            warn("[HOP] FAILED! JobId unchanged. Retrying with new server...")
            task.wait(1)
        end
    end
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

-- ฟังก์ชันเช็คว่าพร้อมซื้อ Sanguine Art หรือยัง
local function CanBuySanguineArt()
    local response1, response2
    local maxRetries = 5
    local retryDelay = 1
    
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
    
    if response1 == nil or response2 == nil then
        warn("WARNING: Failed to get response from BuySanguineArt!")
        warn("Hopping server due to failed responses...")
        showNotification("Failed to get response! Hopping server...", 3)
        task.wait(3)
        HopServer()
        return false, nil
    end
    
    return response1 == 0 and response2 == 0, response1
end

-- ================= LOADSTRING EXECUTION =================

-- ฟังก์ชันโหลด loadstring แบบธรรมดา (ไม่ verify)
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

-- Hook print/warn ที่ระดับ Lua เพื่อจับข้อความที่ console ของสคริปนอกพิมพ์ออกมา
-- (บาง executor console ของมันเองไม่ผ่าน LogService เลย ต้อง hook ตรงๆ)
local function HookOutputFunctions(onMessage)
    local hookFn = (typeof(hookfunction) == "function" and hookfunction)
        or (typeof(replaceclosure) == "function" and replaceclosure)
        or nil
    
    local restoreFns = {}
    
    if not hookFn then
        return restoreFns
    end
    
    pcall(function()
        local origPrint = print
        local newPrint
        newPrint = hookFn(print, function(...)
            local args = {...}
            for _, v in ipairs(args) do
                onMessage(tostring(v))
            end
            return newPrint(...)
        end)
        table.insert(restoreFns, function()
            pcall(function() hookFn(print, origPrint) end)
        end)
    end)
    
    pcall(function()
        local origWarn = warn
        local newWarn
        newWarn = hookFn(warn, function(...)
            local args = {...}
            for _, v in ipairs(args) do
                onMessage(tostring(v))
            end
            return newWarn(...)
        end)
        table.insert(restoreFns, function()
            pcall(function() hookFn(warn, origWarn) end)
        end)
    end)
    
    return restoreFns
end

-- ฟังก์ชันโหลด loadstring พร้อม "verify" ว่าสคริปโหลดจริงหรือไม่
-- ตรวจสอบ 2 ทาง: 1) LogService (ช่องทาง Roblox จริง)  2) Hook print/warn ตรงๆ (เผื่อ console แยกไม่ผ่าน LogService)
-- ถ้าไม่เจอข้อความยืนยันภายในเวลาที่กำหนด จะถือว่าโหลดไม่สำเร็จและลองใหม่
local function ExecuteLoadStringWithVerification(url, successPatterns, maxRetries, timeoutPerAttempt)
    if not url or url == "" then
        warn("LoadString URL is empty, skipping")
        return false
    end
    
    successPatterns = successPatterns or {"Session verified successfully"}
    maxRetries = maxRetries or 5
    timeoutPerAttempt = timeoutPerAttempt or 15
    
    for attempt = 1, maxRetries do
        warn(string.format("[LoadString] Attempt %d/%d -> %s", attempt, maxRetries, url))
        
        local verified = false
        
        local function checkText(msg)
            if verified then return end
            if typeof(msg) ~= "string" then return end
            for _, pattern in ipairs(successPatterns) do
                if string.find(msg, pattern, 1, true) then
                    verified = true
                    break
                end
            end
        end
        
        local connection = LogService.MessageOut:Connect(function(msg, msgType)
            checkText(msg)
        end)
        
        local restoreHooks = HookOutputFunctions(checkText)
        
        local success, result = pcall(function()
            local code = game:HttpGet(url)
            return loadstring(code)()
        end)
        
        if not success then
            warn("[LoadString] Execution error:", result)
        end
        
        local waited = 0
        while not verified and waited < timeoutPerAttempt do
            task.wait(1)
            waited += 1
        end
        
        connection:Disconnect()
        for _, restoreFn in ipairs(restoreHooks) do
            restoreFn()
        end
        
        if verified then
            warn("[LoadString] Verified successfully on attempt", attempt)
            return true
        end
        
        warn("[LoadString] Not verified within", timeoutPerAttempt, "sec. Retrying...")
        showNotification("Script didn't confirm loading, retrying...", 3)
        task.wait(2)
    end
    
    warn("[LoadString] Failed to verify after", maxRetries, "attempts")
    showNotification("LoadString failed to verify after retries!", 5)
    return false
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
    warn("=== Player Data ===")
    warn("Username:", PlayerData.Username)
    warn("Has Purchased:", PlayerData.HasPurchased)
    warn("Has Hopped:", PlayerData.HasHopped)
    warn("==================")
    
    warn("Checking conditions for loadstring selection...")
    
    local shouldBuy, response = CanBuySanguineArt()
    local heartCount = GetLeviathanHeartCount()
    
    warn("Response:", response)
    warn("Leviathan Heart Count:", heartCount)
    
    local selectedLoadString
    local currentMode = ""
    
    if PlayerData.HasPurchased and PlayerData.HasHopped then
        warn("Already purchased and hopped! Checking if Sanguine Art is in backpack...")
        
        local hasSanguineArt = HasSanguineArtInBackpack()
        
        if hasSanguineArt then
            warn("Sanguine Art found in backpack! Using LoadString3")
            currentMode = "LoadString3"
            selectedLoadString = Config.LoadString3
            
            createStatusUI("Status: Farm Mastery", nil)
            
            if selectedLoadString and selectedLoadString ~= "" then
                warn("Executing LoadString3 with verification...")
                showNotification("Starting Farm Mastery...", 3)
                ExecuteLoadStringWithVerification(selectedLoadString, {"Session verified successfully", "Whitelist verified successfully"}, 5, 15)
            else
                warn("LoadString3 is empty or not configured")
                showNotification("LoadString3 not configured!", 3)
            end
            
            warn("Script completed - Sanguine Art process finished")
            return
        else
            warn("Sanguine Art not found in backpack! Resetting data and going to buy...")
            PlayerData.HasPurchased = false
            PlayerData.HasHopped = false
            SavePlayerData(PlayerData)
            showNotification("Sanguine Art not found! Going to buy...", 3)
        end
    end
    
    if response == 1 then
        warn("Sanguine Art already purchased!")
        
        if not PlayerData.HasPurchased then
            PlayerData.HasPurchased = true
            SavePlayerData(PlayerData)
        end
        
        if not PlayerData.HasHopped then
            warn("Need to hop server first...")
            showNotification("Purchased! Hopping server...", 3)
            task.wait(2)
            HopServer()
            return
        else
            currentMode = "LoadString3"
            selectedLoadString = Config.LoadString3
            
            createStatusUI("Status: Farm Mastery", nil)
            
            if selectedLoadString and selectedLoadString ~= "" then
                warn("Executing LoadString3 with verification...")
                showNotification("Starting Farm Mastery...", 3)
                ExecuteLoadStringWithVerification(selectedLoadString, {"Session verified successfully", "Whitelist verified successfully"}, 5, 15)
            else
                warn("LoadString3 is empty or not configured")
                showNotification("LoadString3 not configured!", 3)
            end
            
            warn("Script completed - Sanguine Art already owned")
            return
        end
    elseif response == 0 and heartCount > 0 then
        warn("Condition met: Using LoadString2")
        currentMode = "LoadString2"
        selectedLoadString = Config.LoadString2
        
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
        warn("Condition met: Using LoadString1")
        currentMode = "LoadString1"
        selectedLoadString = Config.LoadString1
        
        local debugInfo = string.format("Response1: %s\nResponse2: %s\nHearts: %d", 
            tostring(response), tostring(response), heartCount)
        createStatusUI("Status: Farm Material", debugInfo)
        
        if selectedLoadString and selectedLoadString ~= "" then
            warn("Executing LoadString1 with verification...")
            showNotification("Starting Farm Material...", 3)
            ExecuteLoadStringWithVerification(selectedLoadString, {"Session verified successfully", "Whitelist verified successfully"}, 5, 15)
        else
            warn("LoadString1 is empty or not configured")
            showNotification("LoadString1 not configured!", 3)
        end
    end
    
    task.wait(2)
    
    warn("Checking if ready to buy Sanguine Art...")
    
    while true do
        local canBuy, currentResponse = CanBuySanguineArt()
        
        if currentMode == "LoadString1" or currentMode == "LoadString2" then
            local heartCount2 = GetLeviathanHeartCount()
            local debugInfo = string.format("Response1: %s\nResponse2: %s\nHearts: %d", 
                tostring(currentResponse), tostring(currentResponse), heartCount2)
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
    
    warn("Checking current location...")
    local isInSea3 = IsInThirdSea()
    
    if not isInSea3 then
        warn("Not in Third Sea, traveling...")
        showNotification("Traveling to Third Sea...", 3)
        updateStatusUI("Status: Traveling to Sea 3", nil)
        
        pcall(function()
            CommF:InvokeServer("TravelZou")
        end)
        
        task.wait(15)
        
        local maxWaitTime = 60
        local waitedTime = 0
        
        repeat
            task.wait(2)
            waitedTime = waitedTime + 2
            isInSea3 = IsInThirdSea()
            
            if waitedTime >= maxWaitTime and not isInSea3 then
                warn("Failed to reach Third Sea after 60 seconds")
                showNotification("Failed to travel! Retrying...", 3)
                pcall(function()
                    CommF:InvokeServer("TravelZou")
                end)
                waitedTime = 0
            end
        until isInSea3 or waitedTime >= 120
        
        if not isInSea3 then
            warn("Still not in Third Sea after multiple attempts, hopping server...")
            showNotification("Travel failed! Hopping server...", 3)
            task.wait(2)
            HopServer()
            return
        end
    else
        warn("Already in Third Sea!")
    end

    warn("Now in Third Sea - PlaceId:", game.PlaceId)
    showNotification("Arrived at Third Sea!", 3)

    warn("Flying up...")
    updateStatusUI("Status: Flying Up", nil)
    FlyUp(120)

    task.wait(1)

    local reachedShafi = false
    local purchaseComplete = false
    
    task.spawn(function()
        while not purchaseComplete do
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local distance = (hrp.Position - SHAFI_CFRAME.Position).Magnitude
                
                if distance > 50 then
                    warn("Distance to Shafi:", distance, "- Tweening again...")
                    updateStatusUI("Status: Going to Shafi", nil)
                    showNotification("Going to Shafi...", 3)
                    
                    pcall(function()
                        TweenTo(SHAFI_CFRAME)
                    end)
                    
                    reachedShafi = true
                else
                    if not reachedShafi then
                        warn("Reached Shafi!")
                        reachedShafi = true
                    end
                end
            else
                warn("Character died! Waiting for respawn...")
                updateStatusUI("Status: Respawning...", nil)
                
                repeat task.wait(1) until LocalPlayer.Character
                
                warn("Respawned! Flying up again...")
                task.wait(1)
                FlyUp(120)
                task.wait(1)
            end
            
            task.wait(2)
        end
    end)

    repeat task.wait(1) until reachedShafi
    
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
            
            purchaseComplete = true
            
            PlayerData.HasPurchased = true
            SavePlayerData(PlayerData)
            
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

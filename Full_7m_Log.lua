Config = Config or {
    Team = "Pirates", -- "Pirates" หรือ "Marines"
    Configuration = {
    }
}

repeat task.wait(5) until game:IsLoaded()
warn("Script Loaded!")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local CommF = ReplicatedStorage.Remotes.CommF_

getgenv().LOADED = true
warn("[", os.date("%H:%M:%S"), "] LOADED = true")

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

local THIRD_SEA_PLACEIDS = {
    [7449423635] = true,
    [100117331123089] = true
}

local TWEEN_SPEED = 300

local SHAFI_CFRAME = CFrame.new(
    -16516.078125, 23.594921112060547, -189.36460876464844
)

local function IsInThirdSea()
    return THIRD_SEA_PLACEIDS[game.PlaceId] == true
end

-- ฟังก์ชันเช็คว่าพร้อมซื้อ Sanguine Art หรือยัง
local function CanBuySanguineArt()
    local response1, response2
    
    pcall(function()
        response1 = CommF:InvokeServer("BuySanguineArt", true)
    end)
    
    pcall(function()
        response2 = CommF:InvokeServer("BuySanguineArt", true)
    end)
    
    warn("BuySanguineArt Response 1:", response1)
    warn("BuySanguineArt Response 2:", response2)
    
    -- ถ้าทั้ง 2 response เป็น 0 แสดงว่าแลกแล้วพร้อมซื้อ
    return response1 == 0 and response2 == 0
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

task.spawn(function()
    -- เช็คว่าพร้อมซื้อ Sanguine Art หรือยัง
    warn("Checking if ready to buy Sanguine Art...")
    
    while true do
        if CanBuySanguineArt() then
            warn("Ready to buy Sanguine Art! Starting main task...")
            break
        else
            warn("Not ready yet. Waiting 15 seconds...")
            task.wait(15)
        end
    end
    
    -- เริ่มทำงานหลักเมื่อพร้อมซื้อแล้ว
    if not IsInThirdSea() then
        warn("Traveling to Third Sea...")
        CommF:InvokeServer("TravelZou")
        task.wait(15)
    end

    repeat task.wait(1) until IsInThirdSea()
    warn("Now in Third Sea")

    warn("Flying up...")
    FlyUp(120)

    task.wait(1)

    warn("Tweening to Shafi...")
    TweenTo(SHAFI_CFRAME)

    task.wait(1)

    warn("Start buying Sanguine Art...")

    while true do
        local result = CommF:InvokeServer("BuySanguineArt")
        warn("Buy Result:", result)

        if result == 1 or result == 2 then
            warn("Sanguine Art acquired!")
            break
        end

        task.wait(3)
    end
end)

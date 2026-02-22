Config = Config or {
    Team = "Pirates",
    Configuration = {}
}

repeat task.wait() until game:IsLoaded()
warn("Script Loaded!")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local CommF = ReplicatedStorage.Remotes.CommF_

getgenv().LOADED = true
warn("[", os.date("%H:%M:%S"), "] LOADED = true")

-- เลือกทีม
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

-- 🔥 เริ่มทำงานทันที
task.spawn(function()

    -- ไป Third Sea ถ้ายังไม่อยู่
    if not IsInThirdSea() then
        warn("Traveling to Third Sea...")
        pcall(function()
            CommF:InvokeServer("TravelZou")
        end)
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

    -- ซื้อวนเลย
    while true do
        local result
        pcall(function()
            result = CommF:InvokeServer("BuySanguineArt")
        end)

        warn("Buy Result:", result)

        if result == 1 or result == 2 then
            warn("Sanguine Art acquired!")
            break
        end

        task.wait(3)
    end
end)

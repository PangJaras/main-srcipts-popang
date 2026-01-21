repeat task.wait() until game:IsLoaded()
repeat task.wait() until _G.Horst_SetDescription
repeat task.wait() until _G.LockRaceConfig

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Data = LocalPlayer:WaitForChild("Data")

local CommF = function(...)
	return ReplicatedStorage.Remotes.CommF_:InvokeServer(...)
end

-- ===== หา Group =====
local ActiveConfig, GroupName

for _, group in ipairs(_G.LockRaceConfig.Groups or {}) do
	for _, user in ipairs(group.Users or {}) do
		if user == LocalPlayer.Name then
			ActiveConfig = group
			GroupName = group.Name
			break
		end
	end
	if ActiveConfig then break end
end

if not ActiveConfig or not _G.LockRaceConfig.Enable then
	return
end

-- ===== Refresh Player Data =====
local PlayerData = {}

local function RefreshPlayerData()
	for _, v in ipairs(Data:GetChildren()) do
		pcall(function()
			PlayerData[v.Name] = v.Value
		end)
	end
end

RefreshPlayerData()

-- ===== Get Race Info =====
local function GetRaceInfo()
	local race = tostring(Data.Race.Value)
	local v = "V1"

	if Data.Race:FindFirstChild("Evolved") then
		v = "V2"
	end
	if CommF("Wenlocktoad", "info") == -2 then
		v = "V3"
	end
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("RaceTransformed") then
		v = "V4"
	end

	return race, v
end

-- ===== Auto Roll Race =====
local Rolling = false

local function AutoRollRace()
	local auto = ActiveConfig.AutoRoll
	if not auto or not auto.Enable or Rolling then return end

	RefreshPlayerData()

	if PlayerData.Fragments < (auto.MinFragments or 3500) then
		return
	end

	if table.find(auto.ForceRace or {}, PlayerData.Race) then
		return
	end

	Rolling = true
	CommF("BlackbeardReward", "Reroll", "2")
	task.wait(6)
	RefreshPlayerData()
	Rolling = false
end

-- ===== Check Done =====
local DoneTriggered = false

local function CheckDone(race, v)
	if race ~= ActiveConfig.Race then return false end

	if ActiveConfig.Lock_V then
		return v == ActiveConfig.Ability
	end

	if ActiveConfig.Ability == "V1" then
		return true
	end

	return v == ActiveConfig.Ability
end

-- ===== Update Description =====
local function UpdateDescription()
	local race, v = GetRaceInfo()

	pcall(function()
		_G.Horst_SetDescription(
			string.format("🧬 Race: %s [%s] | %s", race, v, GroupName)
		)
	end)

	AutoRollRace()

	if not DoneTriggered and CheckDone(race, v) then
		DoneTriggered = true
		task.wait(0.2)
		pcall(function()
			_G.Horst_AccountChangeDone()
		end)
	end
end

while true do
	pcall(UpdateDescription)
	task.wait(15)
end

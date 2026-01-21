repeat task.wait() until game:IsLoaded()
repeat task.wait() until _G.Horst_SetDescription

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Data = LocalPlayer:WaitForChild("Data")

local CommF = function(...)
	return ReplicatedStorage.Remotes.CommF_:InvokeServer(...)
end

-- ===== DEBUG =====
local function DebugPrint(...)
	if _G.LockRaceConfig.Debug then
		print("[LockRace]", ...)
	end
end

-- ===== FIND GROUP =====
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
	DebugPrint("User not in any group or system disabled")
	return
end

DebugPrint("Active Group:", GroupName)

-- ===== PLAYER DATA =====
local PlayerData = {}

local function RefreshPlayerData()
	for _, v in ipairs(Data:GetChildren()) do
		pcall(function()
			PlayerData[v.Name] = v.Value
		end)
	end
end

RefreshPlayerData()

-- ===== RACE INFO =====
local function GetRaceInfo()
	local race = tostring(Data.Race.Value)
	local v = "V1"

	if Data.Race:FindFirstChild("Evolved") then v = "V2" end
	if CommF("Wenlocktoad", "info") == -2 then v = "V3" end
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("RaceTransformed") then
		v = "V4"
	end

	return race, v
end

-- ===== AUTO ROLL =====
local Rolling = false
local LastRoll = 0

local function AutoRollRace()
	local auto = ActiveConfig.AutoRoll
	if not auto or not auto.Enable or Rolling then return end

	if tick() - LastRoll < 3 then return end

	RefreshPlayerData()

	if PlayerData.Fragments < (auto.MinFragments or 3500) then
		DebugPrint("Not enough fragments:", PlayerData.Fragments)
		return
	end

	if table.find(auto.ForceRace or {}, PlayerData.Race) then
		DebugPrint("Race OK:", PlayerData.Race)
		return
	end

	Rolling = true
	LastRoll = tick()

	DebugPrint("Rolling race... Current:", PlayerData.Race)
	CommF("BlackbeardReward", "Reroll", "2")

	task.wait(3)
	RefreshPlayerData()
	DebugPrint("New Race:", PlayerData.Race)

	Rolling = false
end

-- ===== DONE CHECK =====
local DoneTriggered = false
local StartTime = tick()

local function CheckDone(race, v)
	if tick() - StartTime < 15 then
		return false
	end

	if race ~= ActiveConfig.Race then return false end

	if ActiveConfig.Lock_V then
		return v == ActiveConfig.Ability
	end

	if ActiveConfig.Ability == "V1" then
		return true
	end

	return v == ActiveConfig.Ability
end

-- ===== UPDATE =====
local LastDesc = 0

local function Update()
	local race, v = GetRaceInfo()

	if tick() - LastDesc >= 5 then
		LastDesc = tick()
		pcall(function()
			_G.Horst_SetDescription(
				string.format("🧬 Race: %s [%s] : %s", race, v, GroupName)
			)
		end)
		DebugPrint("Description updated:", race, v)
	end

	AutoRollRace()

	if not DoneTriggered and CheckDone(race, v) then
		DoneTriggered = true
		DebugPrint("DONE ✔ Race & Ability matched")
		task.wait(0.2)
		pcall(function()
			_G.Horst_AccountChangeDone()
		end)
	end
end

while true do
	pcall(Update)
	task.wait(1)
end

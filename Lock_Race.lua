repeat task.wait() until game:IsLoaded()
repeat task.wait() until _G.Horst_SetDescription
repeat task.wait() until _G.LockRaceConfig

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Data = LocalPlayer:WaitForChild("Data")

local CommF = function(command, ...)
	return ReplicatedStorage.Remotes.CommF_:InvokeServer(command, ...)
end

-- ================= FIND USER CONFIG =================
local ActiveConfig = nil
local ActiveGroupName = nil

if _G.LockRaceConfig.Enable then
	for _, group in ipairs(_G.LockRaceConfig.Groups or {}) do
		for _, username in ipairs(group.Users or {}) do
			if username == LocalPlayer.Name then
				ActiveConfig = group
				ActiveGroupName = group.Name or "Unknown"
				break
			end
		end
		if ActiveConfig then break end
	end
end

-- ไม่อยู่ในกลุ่มใด → หยุด
if not ActiveConfig then
	return
end
-- ====================================================

local DoneTriggered = false

-- ================= RACE INFO =================
local function GetRaceInfo()
	local raceName = tostring(Data.Race.Value)
	local raceV = "V1"

	if Data.Race:FindFirstChild("Evolved") then
		raceV = "V2"
	end

	if CommF("Wenlocktoad", "info") == -2 then
		raceV = "V3"
	end

	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("RaceTransformed") then
		raceV = "V4"
	end

	return raceName, raceV
end
-- =============================================

local function CheckDone(raceName, raceV)
	if raceName ~= ActiveConfig.Race then
		return false
	end

	if ActiveConfig.Lock_V then
		return raceV == ActiveConfig.Ability
	end

	if ActiveConfig.Ability == "V1" then
		return true
	end

	return raceV == ActiveConfig.Ability
end

local function UpdateDescription()
	local raceName, raceV = GetRaceInfo()
	local message = string.format(
		"🧬 Race: %s [%s]",
		raceName,
		raceV
	)

	-- อัปเดตก่อนเสมอ
	pcall(function()
		_G.Horst_SetDescription(message)
	end)

	if not DoneTriggered and CheckDone(raceName, raceV) then
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

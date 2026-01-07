repeat task.wait() until game:IsLoaded()
repeat task.wait() until _G.Horst_SetDescription and _G.Horst_AccountChangeDone

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Data = LocalPlayer:WaitForChild("Data")

local CommF = function(command, ...)
	return ReplicatedStorage.Remotes.CommF_:InvokeServer(command, ...)
end


_G.RaceCheckConfig = {
	Enable = true,
	Race = "Cyborg",
	Ability = "V3",
	Lock_V = true,
}


local DoneTriggered = false


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


local function CheckDone(raceName, raceV)
	if not _G.RaceCheckConfig.Enable then
		return false
	end

	if raceName ~= _G.RaceCheckConfig.Race then
		return false
	end

	local targetV = _G.RaceCheckConfig.Ability
	local lockV = _G.RaceCheckConfig.Lock_V


	if lockV then
		return raceV == targetV
	end


	if targetV == "V1" then
		return true
	end

	return raceV == targetV
end


local function UpdateDescription()
	local raceName, raceV = GetRaceInfo()
	local message = string.format("🧬 Race: %s [%s]", raceName, raceV)

	-- ต้องอัปเดต description ก่อนเสมอ
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

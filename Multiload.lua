local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local playerName = LocalPlayer.Name

local function isInTable(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

for _, data in pairs(_G.Config) do
    if data.Names and data.Script then
        if isInTable(data.Names, playerName) then
            loadstring(game:HttpGet(data.Script))()
            return
        end
    end
end

warn("[Script Loader] ไม่พบชื่อใน Config")

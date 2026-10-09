-- [[ Stealth Hub ]]
-- discord.gg/hqE5drDHF7

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

local PLACE_ID = tostring(game.PlaceId)
local BASE_URL = "https://raw.githubusercontent.com/requiemzc/Stealth/main/games"

if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(1)

local scriptUrl = BASE_URL .. "/" .. PLACE_ID .. ".lua"

local ok, err = pcall(function()
    loadstring(game:HttpGet(scriptUrl))()
end)

if not ok then
    local gameName = "Unknown"
    pcall(function()
        gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Stealth",
            Text = "Not supported: " .. gameName,
            Duration = 8,
        })
    end)
end

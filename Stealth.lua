-- [[ Stealth Hub ]]
-- discord.gg/hqE5drDHF7

local BASE = "https://raw.githubusercontent.com/requiemzc/Stealth/main/games"

local function tryLoad(id)
    local url = BASE .. "/" .. tostring(id) .. ".lua"
    local ok, result = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and result and #result > 100 then
        local fn = loadstring(result)
        if fn then
            fn()
            return true
        end
    end
    return false
end

local function loadGameScript()
    local pid = game.PlaceId
    local gid = game.GameId

    -- Try PlaceId first
    if tryLoad(pid) then return end

    -- Try GameId (universe ID)
    if tryLoad(gid) then return end

    -- Not found
    local gameName = "Unknown"
    pcall(function()
        gameName = game:GetService("MarketplaceService"):GetProductInfo(pid).Name
    end)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Stealth",
            Text = "Not supported: " .. gameName,
            Duration = 8,
        })
    end)
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

task.wait(1)
loadGameScript()

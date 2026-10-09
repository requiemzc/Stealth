-- [[ Stealth Hub — Auto-Loader ]]
--
-- Automatically detects the current game by PlaceId and loads the
-- corresponding script. No buttons, no UI — just paste and it works.
--
-- If the game isn't supported, shows a notification.
-- Discord: discord.gg/hqE5drDHF7

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

local PLACE_ID = tostring(game.PlaceId)
local BASE_URL = "https://raw.githubusercontent.com/requiemzc/Stealth/main/games"

-- PlaceId → Game name mapping (auto-generated)
-- The actual script files are named "Game Name [PlaceId].lua"
-- We use the PlaceId to construct the URL

local function getGameName()
    local name = "Unknown"
    pcall(function()
        local info = MarketplaceService:GetProductInfo(game.PlaceId)
        if info and info.Name then name = info.Name end
    end)
    return name
end

local function urlEncode(str)
    str = str:gsub("([^%w _-])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    str = str:gsub(" ", "%%20")
    return str
end

-- Try to load the script for this PlaceId
local function loadGameScript()
    local gameName = getGameName()

    -- Build the URL: games/Game Name [PlaceId].lua
    -- We need to URL-encode the filename
    local fileName = gameName .. " [" .. PLACE_ID .. "].lua"
    local encodedName = urlEncode(fileName)
    local scriptUrl = BASE_URL .. "/" .. encodedName

    print("[Stealth] PlaceId: " .. PLACE_ID)
    print("[Stealth] Game: " .. gameName)
    print("[Stealth] Loading: " .. scriptUrl)

    local success, err = pcall(function()
        local source = game:HttpGet(scriptUrl)
        if source and #source > 0 then
            loadstring(source)()
        else
            error("Empty response")
        end
    end)

    if not success then
        warn("[Stealth] Failed to load: " .. tostring(err))

        -- Fallback: try with the raw filename (no encoding)
        -- Sometimes GitHub raw URLs work differently with special chars
        pcall(function()
            local source = game:HttpGet(BASE_URL .. "/" .. fileName)
            if source and #source > 0 and not source:find("404") then
                loadstring(source)()
                print("[Stealth] Loaded via fallback URL!")
                return
            end
        end)

        -- If still failed, show notification
        pcall(function()
            local StarterGui = game:GetService("StarterGui")
            StarterGui:SetCore("SendNotification", {
                Title = "Stealth Hub",
                Text = "Game not supported yet: " .. gameName .. "\nPlaceId: " .. PLACE_ID,
                Duration = 10,
            })
        end)

        print("[Stealth] This game is not supported. PlaceId: " .. PLACE_ID)
        print("[Stealth] Discord: discord.gg/hqE5drDHF7")
    end
end

-- Wait for game to load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Small delay to let services initialize
task.wait(1)

loadGameScript()

-- [[ Stealth | Main launcher (Orion Lib / Rayfield) ]]
-- Script selector built with Orion Lib — closes when a script is loaded.

local STEALTH_API = "https://sstealth.vercel.app"

------------------------------------------------------------
-- 1. Load Orion Lib
------------------------------------------------------------
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

------------------------------------------------------------
-- 2. Script catalog
------------------------------------------------------------
local SCRIPTS = {
    { name = "MM2 — Murder Mystery 2", desc = "Weapon spawner + visualizer.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/MM2.lua" },
    { name = "Deagle Arena", desc = "Kill all - works in ranked", url = "https://raw.githubusercontent.com/requiemzc/Stealth/refs/heads/main/scripts/Deaglearena.lua" },
    { name = "Chapter 1 — Farmhouse", desc = "Auto farm hay, sell, collect gems.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/Farmhouse.lua" },
    { name = "Jump for Animals", desc = "Auto train squats, steal/hatch eggs.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/JumpForAnimals.lua" },
    { name = "Defeat Anime RNG", desc = "Auto roll, farm waves, buy weapons.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/DefeatAnimeRNG.lua" },
    { name = "catmio — Remote Spy", desc = "Universal remote spy.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/CatmioRemoteSpy.lua" },
    { name = "Star RNG", desc = "Auto roll, buy, place best stars.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/StarRNG.lua" },
    { name = "Mine a Mountain — Crystal ESP", desc = "Highlights high-value crystals.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/CrystalESP.lua" },
}

local PLACE_ID = game.PlaceId
local gameName = "Unknown"
pcall(function()
    local info = game:GetService("MarketplaceService"):GetProductInfo(PLACE_ID)
    if info and info.Name then gameName = info.Name end
end)

local loaded = {}
local Window

local function loadScript(entry)
    if loaded[entry.url] then
        OrionLib:MakeNotification({ Title = "Stealth", Content = entry.name .. " already loaded.", Time = 3 })
        return
    end
    loaded[entry.url] = true

    OrionLib:MakeNotification({ Title = "Stealth", Content = "Loading " .. entry.name .. "...", Time = 3 })

    -- Webhook log
    pcall(function()
        local HttpService = game:GetService("HttpService")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local username = LocalPlayer and LocalPlayer.Name or "?"
        local displayName = LocalPlayer and LocalPlayer.DisplayName or username
        local userId = LocalPlayer and LocalPlayer.UserId or 0
        local placeName = "?"
        pcall(function() local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) if info and info.Name then placeName = info.Name end end)
        local payload = { ["username"] = "Stealth Script Logger", ["embeds"] = {{ ["title"] = "🎮 Script Cargado", ["description"] = "Un usuario ha cargado **" .. entry.name .. "**.", ["color"] = 0x30FF6A, ["fields"] = { { ["name"] = "Script", ["value"] = entry.name, ["inline"] = true }, { ["name"] = "Usuario", ["value"] = username, ["inline"] = true }, { ["name"] = "Display", ["value"] = displayName, ["inline"] = true }, { ["name"] = "Juego", ["value"] = placeName, ["inline"] = true }, { ["name"] = "Place ID", ["value"] = tostring(game.PlaceId), ["inline"] = true } }, ["timestamp"] = DateTime.now():ToIsoDate(), ["footer"] = { ["text"] = "Stealth Hub" } }} }
        local reqFn = request or http_request or (syn and syn.request) or nil
        if reqFn then pcall(reqFn, { Url = "https://discord.com/api/webhooks/1521083124061310996/RBbz1Hc4X_HHSwZvwA7ftutwMnPXgEb7R-R9z_jTBR3ZCdFt3wVj3X4G5UgBanzOjei9", Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(payload) }) end
    end)

    -- Destroy the Orion window so it disappears
    task.spawn(function()
        task.wait(0.5)
        pcall(function() OrionLib:Destroy() end)
        local ok, err = pcall(function() loadstring(game:HttpGet(entry.url))() end)
        if not ok then
            warn("[Stealth] Failed to load " .. entry.name .. ": " .. tostring(err))
            loaded[entry.url] = nil
        end
    end)
end

------------------------------------------------------------
-- 3. Create Orion window
------------------------------------------------------------
Window = OrionLib:CreateWindow({
    Name = "Stealth Hub",
    HidePremium = true,
    SaveConfig = false,
    IntroText = "Stealth Hub",
    IntroIcon = "rbxassetid://94734287536234",
})

------------------------------------------------------------
-- 4. Scripts tab
------------------------------------------------------------
local ScriptsTab = Window:MakeTab({
    Name = "Scripts",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false,
})

ScriptsTab:AddParagraph("Game: " .. gameName, "Place ID: " .. tostring(PLACE_ID))
ScriptsTab:AddDivider()

for _, entry in ipairs(SCRIPTS) do
    ScriptsTab:AddButton({
        Name = entry.name,
        Callback = function()
            loadScript(entry)
        end,
    })
end

------------------------------------------------------------
-- 5. Info tab
------------------------------------------------------------
local InfoTab = Window:MakeTab({
    Name = "Info",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false,
})

InfoTab:AddParagraph("Stealth Hub", "Multi-script launcher. Pick a script and click it to load.")
InfoTab:AddDivider()

InfoTab:AddButton({
    Name = "Copy Discord Link",
    Callback = function()
        pcall(function()
            if setclipboard then
                setclipboard("https://discord.gg/hqE5drDHF7")
                OrionLib:MakeNotification({ Title = "Stealth", Content = "Discord link copied!", Time = 2 })
            end
        end)
    end,
})

InfoTab:AddButton({
    Name = "Unload Hub",
    Callback = function()
        OrionLib:Destroy()
    end,
})

------------------------------------------------------------
-- 6. Init
------------------------------------------------------------
OrionLib:MakeNotification({ Title = "Stealth Hub", Content = "Welcome! Pick a script.", Time = 4 })
OrionLib:Init()

print("[Stealth] Main launcher loaded with Orion Lib")

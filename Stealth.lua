-- [[ Catmio Reborn ]]
-- discord.gg/hqE5drDHF7

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Naellx/ObsidianUltra/main/Library.lua"))()

local SCRIPTS = {
    { name = "MM2 — Murder Mystery 2", desc = "Weapon spawner + visualizer.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/MM2.lua" },
    { name = "Blox Fruits", desc = "Quantum Onyx wrapper.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/BloxFruits.lua" },
    { name = "Rivals", desc = "Combat script - aimbot, ESP, fly.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/Rivals.lua" },
    { name = "Murderers VS Sheriffs Duels", desc = "Auto-kill + auto-equip gun.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/MVSDuel.lua" },
    { name = "Deagle Arena", desc = "Kill all - works in ranked.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/Deaglearena.lua" },
    { name = "Chapter 1 — Farmhouse", desc = "Auto farm hay, sell, collect gems.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/Farmhouse.lua" },
    { name = "Defeat Anime RNG", desc = "Auto roll, farm waves, buy weapons.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/DefeatAnimeRNG.lua" },
    { name = "Huss Valley", desc = "Auto farm, auto quest, auto buy.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/HussValley.lua" },
    { name = "catmio — Remote Spy", desc = "Universal remote spy.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/CatmioRemoteSpy.lua" },
    { name = "Star RNG", desc = "Auto roll, buy, place best stars.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/StarRNG.lua" },
}

local PLACE_ID = game.PlaceId
local gameName = "Unknown"
pcall(function()
    local info = game:GetService("MarketplaceService"):GetProductInfo(PLACE_ID)
    if info and info.Name then gameName = info.Name end
end)

local loaded = {}

local function loadScript(entry)
    if loaded[entry.url] then return end
    loaded[entry.url] = true

    Library:Notify({ Title = "Catmio Reborn", Description = "Loading " .. entry.name .. "...", Time = 3 })

    task.spawn(function()
        task.wait(0.5)
        pcall(function() Library:Unload() end)
        local ok, err = pcall(function() loadstring(game:HttpGet(entry.url))() end)
        if not ok then
            warn("[Catmio Reborn] Failed to load " .. entry.name .. ": " .. tostring(err))
            loaded[entry.url] = nil
        end
    end)
end

local Window = Library:CreateWindow({
    Title = "Catmio Reborn",
    Footer = "discord.gg/hqE5drDHF7",
    NotifySide = "Right",
    AutoLoad = true,
})

local ScriptsTab = Window:AddTab({ Name = "Scripts", Icon = "box", Description = "Available scripts" })
local ScriptsBox = ScriptsTab:AddLeftGroupbox("Scripts")

ScriptsBox:AddLabel("Game: " .. gameName, true)
ScriptsBox:AddLabel("Place ID: " .. tostring(PLACE_ID), true)
ScriptsBox:AddDivider()

for _, entry in ipairs(SCRIPTS) do
    ScriptsBox:AddButton({
        Text = entry.name,
        Tooltip = entry.desc,
        Callback = function()
            loadScript(entry)
        end,
    })
end

local InfoTab = Window:AddTab({ Name = "Info", Icon = "info", Description = "About" })
local InfoBox = InfoTab:AddLeftGroupbox("About")

InfoBox:AddLabel("Catmio Reborn is a multi-script launcher.", true)
InfoBox:AddDivider()
InfoBox:AddButton({
    Text = "Copy Discord Link",
    Callback = function()
        pcall(function()
            if setclipboard then
                setclipboard("https://discord.gg/hqE5drDHF7")
                Library:Notify({ Title = "Catmio Reborn", Description = "Discord link copied!", Time = 2 })
            end
        end)
    end,
})
InfoBox:AddButton({
    Text = "Unload Hub",
    Callback = function()
        Library:Unload()
    end,
})

Library:Notify({ Title = "Catmio Reborn", Description = "Welcome! Pick a script.", Time = 4 })

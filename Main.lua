-- [[ Stealth | Main launcher with script selector menu ]]
--
-- This file is loaded by Stealth.lua AFTER the user's key is validated.
-- It shows a Rayfield UI where the user can pick which script to run.
--
-- Each script lives in its own file under the `scripts/` folder of the repo.
-- Adding a new script = drop the file in `scripts/` + add one line to SCRIPTS below.
--
-- Repository: https://github.com/requiemzc/Stealth

------------------------------------------------------------
-- 1. Load Rayfield
------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

------------------------------------------------------------
-- 2. Script catalog
--    Add one entry per script you want to show in the menu.
--    `name`  — display name shown on the button.
--    `url`   — RAW URL of the script file (raw.githubusercontent.com).
--    `desc`  — short description shown next to the button.
--    `icon`  — optional Lucide icon name (https://lucide.dev/icons/).
------------------------------------------------------------
local SCRIPTS = {
    {
        name = "Defeat Anime RNG",
        desc = "Auto-roll, auto-farm waves, auto-buy weapons, prestige.",
        icon = "sprout",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/DefeatAnimeRNG.lua",
    },
    {
        name = "Blox Fruits",
        desc = "Auto-farm, auto-raid, fruit notifier.",
        icon = "sword",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/BloxFruits.lua",
    },
    {
        name = "Pet Sim 99",
        desc = "Auto-hatch, auto-sell, auto-upgrade pets.",
        icon = "paw-print",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/PetSim99.lua",
    },
    {
        name = "Universal ESP",
        desc = "Player ESP, name tags, distance — works in any game.",
        icon = "eye",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/Universal.lua",
    },
    -- >>> ADD MORE SCRIPTS HERE <<<
    -- {
    --     name = "My New Script",
    --     desc = "What it does.",
    --     icon = "package",
    --     url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/MyNewScript.lua",
    -- },
}

------------------------------------------------------------
-- 3. Helpers
------------------------------------------------------------
local PLACE_ID = game.PlaceId
local gameName = "Unknown game"
pcall(function()
    local info = game:GetService("MarketplaceService"):GetProductInfo(PLACE_ID)
    if info and info.Name then gameName = info.Name end
end)

-- Track which scripts have been loaded so the user can't double-load.
local loaded = {}

local function loadScript(scriptEntry)
    if loaded[scriptEntry.url] then
        Rayfield:Notify({
            Title = "Stealth",
            Content = scriptEntry.name .. " is already loaded.",
            Duration = 3,
            Image = "info",
        })
        return
    end

    Rayfield:Notify({
        Title = "Stealth",
        Content = "Loading " .. scriptEntry.name .. "...",
        Duration = 2,
        Image = "loader-circle",
    })

    local ok, err = pcall(function()
        loadstring(game:HttpGet(scriptEntry.url))()
    end)

    if ok then
        loaded[scriptEntry.url] = true
        Rayfield:Notify({
            Title = "Stealth",
            Content = scriptEntry.name .. " loaded successfully!",
            Duration = 4,
            Image = "check",
        })
    else
        Rayfield:Notify({
            Title = "Stealth",
            Content = "Failed to load " .. scriptEntry.name .. ": " .. tostring(err),
            Duration = 6,
            Image = "x",
        })
    end
end

------------------------------------------------------------
-- 4. Window
------------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name              = "Stealth Hub",
    Icon              = 0,
    LoadingTitle      = "Stealth Hub",
    LoadingSubtitle   = "by requiemzc",
    Theme             = "Default",
    ToggleUIKeybind   = Enum.KeyCode.RightShift,
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = {
        Enabled   = true,
        FolderName = "Stealth",
        FileName  = "StealthHub",
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

------------------------------------------------------------
-- 5. Scripts tab — one button per script in the catalog
------------------------------------------------------------
local ScriptsTab = Window:CreateTab("Scripts", "package")

ScriptsTab:CreateSection("Available scripts")
ScriptsTab:CreateLabel("Current game: " .. gameName)
ScriptsTab:CreateLabel("Place ID: " .. tostring(PLACE_ID))
ScriptsTab:CreateDivider()

for _, s in ipairs(SCRIPTS) do
    ScriptsTab:CreateButton({
        Name     = "Load: " .. s.name,
        Callback = function()
            loadScript(s)
        end,
    })
    if s.desc then
        ScriptsTab:CreateLabel(s.desc)
    end
    ScriptsTab:CreateDivider()
end

------------------------------------------------------------
-- 6. Info tab
------------------------------------------------------------
local InfoTab = Window:CreateTab("Info", "info")

InfoTab:CreateSection("About")
InfoTab:CreateLabel("Stealth Hub — multi-script launcher")
InfoTab:CreateLabel("Repository: github.com/requiemzc/Stealth")
InfoTab:CreateLabel("Key system: stealth.space-z.ai")
InfoTab:CreateDivider()
InfoTab:CreateLabel("Press RightShift to toggle this UI.")
InfoTab:CreateLabel("Loaded scripts keep running even if you close this menu.")

InfoTab:CreateSection("Discord")
InfoTab:CreateButton({
    Name = "Join Discord",
    Callback = function()
        pcall(function()
            setclipboard("https://discord.gg/yourserver")  -- >>> replace <<<
        end)
        Rayfield:Notify({
            Title = "Discord",
            Content = "Invite copied to clipboard!",
            Duration = 3,
            Image = "discord",
        })
    end,
})

------------------------------------------------------------
-- 7. Settings tab
------------------------------------------------------------
local SettingsTab = Window:CreateTab("Settings", "settings")

SettingsTab:CreateSection("Hub")
SettingsTab:CreateButton({
    Name = "Unload Stealth Hub",
    Callback = function()
        Rayfield:Destroy()
    end,
})
SettingsTab:CreateLabel("This closes the launcher UI. Already-loaded scripts keep running.")

SettingsTab:CreateDivider()
SettingsTab:CreateLabel("Configuration is auto-saved by Rayfield.")

------------------------------------------------------------
-- 8. Final
------------------------------------------------------------
Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title   = "Stealth Hub",
    Content = "Welcome! Pick a script from the Scripts tab.",
    Duration = 5,
    Image   = "shield-check",
})

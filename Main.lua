-- [[ Stealth | Main launcher with script selector menu (WindUI) ]]
--
-- This file is loaded by Stealth.lua AFTER the user's key is validated.
-- It shows a WindUI menu where the user can pick which script to run.
--
-- When the user picks a script, this launcher closes itself so only the
-- loaded script's UI remains visible.

------------------------------------------------------------
-- 1. Load WindUI
------------------------------------------------------------
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

------------------------------------------------------------
-- 2. Script catalog
--    Add one entry per script you want to show in the menu.
--    `name`  — display name shown on the button.
--    `desc`  — short description shown under the button.
--    `icon`  — Lucide / Solar icon name (https://lucide.dev or https://icones.js.org/collection/solar).
--    `url`   — RAW URL of the script file (raw.githubusercontent.com).
------------------------------------------------------------
local SCRIPTS = {
    {
        name = "Defeat Anime RNG",
        desc = "Auto-roll, auto-farm waves, auto-buy weapons, prestige.",
        icon = "solar:sprout-bold-duotone",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/DefeatAnimeRNG.lua",
    },
    {
        name = "Blox Fruits",
        desc = "Auto-farm, auto-raid, fruit notifier.",
        icon = "solar:sword-bold-duotone",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/BloxFruits.lua",
    },
    {
        name = "Pet Sim 99",
        desc = "Auto-hatch, auto-sell, auto-upgrade pets.",
        icon = "solar:paw-bold-duotone",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/PetSim99.lua",
    },
    {
        name = "Universal ESP",
        desc = "Player ESP, name tags, distance — works in any game.",
        icon = "solar:eye-bold-duotone",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/Universal.lua",
    },
    -- >>> ADD MORE SCRIPTS HERE <<<
    -- {
    --     name = "My New Script",
    --     desc = "What it does.",
    --     icon = "solar:package-bold-duotone",
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
        WindUI:Notify({
            Title = "Stealth",
            Content = scriptEntry.name .. " is already loaded.",
            Duration = 3,
            Icon = "solar:info-circle-bold",
        })
        return
    end

    -- Run in a spawned thread so we can yield without blocking the UI callback.
    task.spawn(function()
        WindUI:Notify({
            Title = "Stealth",
            Content = "Loading " .. scriptEntry.name .. "...",
            Duration = 2,
            Icon = "solar:download-minimalistic-bold",
        })

        -- Give the notification a moment to render.
        task.wait(0.3)

        -- Destroy the launcher window FIRST, before loading the new script.
        -- WindUI only supports one active window — if we load the new script
        -- while the launcher is still open, the two windows conflict and the
        -- wrong one gets destroyed.
        pcall(function() Window:Destroy() end)

        -- Now load the script. It will create its own fresh WindUI window
        -- that fully replaces this launcher.
        local ok, err = pcall(function()
            loadstring(game:HttpGet(scriptEntry.url))()
        end)

        if ok then
            loaded[scriptEntry.url] = true
            -- The loaded script shows its own "loaded!" notification.
        else
            -- If loading failed, the launcher is already gone.
            -- Show the error via WindUI's global Notify.
            WindUI:Notify({
                Title = "Stealth",
                Content = "Failed to load " .. scriptEntry.name .. ": " .. tostring(err),
                Duration = 6,
                Icon = "solar:danger-triangle-bold",
            })
        end
    end)
end

------------------------------------------------------------
-- 4. Window
------------------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "Stealth Hub",
    Folder = "StealthHub",
    Icon = "solar:shield-keyhole-bold-duotone",
    NewElements = true,
    HideSearchBar = false,

    OpenButton = {
        Title = "Open Stealth Hub",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
        Color = ColorSequence.new(
            Color3.fromHex("#30FF6A"),
            Color3.fromHex("#e7ff2f")
        ),
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

------------------------------------------------------------
-- 5. Scripts tab — one button per script in the catalog
------------------------------------------------------------
local ScriptsSection = Window:Section({
    Title = "Scripts",
})

local ScriptsTab = ScriptsSection:Tab({
    Title = "Available",
    Icon = "solar:package-bold",
    IconShape = "Square",
    Border = true,
})

ScriptsTab:Section({ Title = "Current game" })
ScriptsTab:Section({ Title = "Name: " .. gameName, TextTransparency = 0.35 })
ScriptsTab:Section({ Title = "Place ID: " .. tostring(PLACE_ID), TextTransparency = 0.35 })
ScriptsTab:Space({ Columns = 1 })

ScriptsTab:Section({ Title = "Available scripts" })

for _, s in ipairs(SCRIPTS) do
    local entry = s
    ScriptsTab:Button({
        Title = "Load: " .. entry.name,
        Desc = entry.desc or "",
        Icon = entry.icon or "solar:package-bold",
        Color = Color3.fromHex("#30FF6A"),
        Justify = "Left",
        IconAlign = "Left",
        Callback = function()
            loadScript(entry)
        end,
    })
    ScriptsTab:Space({ Columns = 1 })
end

------------------------------------------------------------
-- 6. Info tab
------------------------------------------------------------
local InfoSection = Window:Section({ Title = "Info" })
local InfoTab = InfoSection:Tab({
    Title = "About",
    Icon = "solar:info-circle-bold",
    IconShape = "Square",
    Border = true,
})

InfoTab:Section({ Title = "About Stealth Hub" })
InfoTab:Section({
    Title = "Stealth Hub is a multi-script launcher.\nPick a script from the Scripts tab and click Load.\nThe launcher will close automatically once a script is loaded.",
    TextTransparency = 0.35,
})
InfoTab:Space({ Columns = 1 })

InfoTab:Section({ Title = "Controls" })
InfoTab:Section({
    Title = "Click the floating green button to toggle this UI.",
    TextTransparency = 0.35,
})
InfoTab:Space({ Columns = 1 })

InfoTab:Section({ Title = "Discord" })
InfoTab:Button({
    Title = "Copy Discord invite",
    Icon = "solar:chat-round-dots-bold",
    Color = Color3.fromHex("#5865F2"),
    Justify = "Left",
    IconAlign = "Left",
    Callback = function()
        pcall(function() setclipboard("https://discord.gg/yourserver") end)  -- >>> replace <<<
        WindUI:Notify({
            Title = "Discord",
            Content = "Invite copied to clipboard!",
            Duration = 3,
            Icon = "solar:chat-round-dots-bold",
        })
    end,
})

------------------------------------------------------------
-- 7. Settings tab
------------------------------------------------------------
local SettingsSection = Window:Section({ Title = "Settings" })
local SettingsTab = SettingsSection:Tab({
    Title = "Hub",
    Icon = "solar:settings-bold",
    IconShape = "Square",
    Border = true,
})

SettingsTab:Section({ Title = "Hub controls" })
SettingsTab:Button({
    Title = "Unload Stealth Hub",
    Desc = "Closes the launcher UI. Already-loaded scripts keep running.",
    Icon = "solar:close-circle-bold",
    Color = Color3.fromHex("#ff4830"),
    Justify = "Left",
    IconAlign = "Left",
    Callback = function()
        Window:Destroy()
    end,
})

SettingsTab:Space({ Columns = 1 })
SettingsTab:Section({
    Title = "Configuration is auto-saved by WindUI to the StealthHub folder.",
    TextTransparency = 0.35,
})

------------------------------------------------------------
-- 8. Welcome notification
------------------------------------------------------------
WindUI:Notify({
    Title = "Stealth Hub",
    Content = "Welcome! Pick a script from the Scripts tab.",
    Duration = 5,
    Icon = "solar:shield-keyhole-bold",
})

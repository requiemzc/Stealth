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
-- WindUI requires elevated thread identity to create Font objects and
-- access certain Instance APIs. Without this, WindUI's Notify() and
-- font loading crash with "lacking capability Plugin".
--
-- The problem: WindUI calls task.spawn internally for notifications and
-- animations, and those new threads inherit the DEFAULT identity, not
-- the elevated one.
--
-- Fix: patch task.spawn / task.defer / task.delay globally so every
-- new thread gets identity 8 (maximum) before running.
--
-- BUT: `task` is a readonly table in Luau, so `task.spawn = ...` throws
-- "attempt to modify a readonly table". We try 3 approaches in order:
--   1. setreadonly(task, false)  → then direct assignment
--   2. hookfunction              → executor-supported function hooking
--   3. Fall back to just elevating the main thread (most executors
--      propagate identity to child threads automatically)

local function _elevateIdentity()
    -- Try every known identity-setting function. Different executors
    -- expose different names. Identity 8 = maximum (executor level).
    pcall(function() if setthreadidentity then setthreadidentity(8) end end)
    pcall(function() if setidentity then setidentity(8) end end)
    pcall(function() if syn and syn.set_thread_identity then syn.set_thread_identity(8) end end)
    pcall(function() if set_thread_context then set_thread_context(8) end end)
    pcall(function() if setcontext then setcontext(8) end end)
end

_elevateIdentity()

local _taskPatched = false

-- Approach 1: unfreeze `task` table and patch directly.
if not _taskPatched then
    pcall(function()
        if setreadonly then setreadonly(task, false) end
        if not isreadonly or not isreadonly(task) then
            local _origSpawn = task.spawn
            local _origDefer  = task.defer
            local _origDelay  = task.delay

            task.spawn = function(fn, ...)
                local args = { ... }
                return _origSpawn(function()
                    _elevateIdentity()
                    if type(fn) == "function" then
                        return fn(table.unpack or unpack, args)
                    end
                end)
            end

            task.defer = function(fn, ...)
                local args = { ... }
                return _origDefer(function()
                    _elevateIdentity()
                    if type(fn) == "function" then
                        return fn(table.unpack or unpack, args)
                    end
                end)
            end

            task.delay = function(time, fn, ...)
                local args = { ... }
                return _origDelay(time, function()
                    _elevateIdentity()
                    if type(fn) == "function" then
                        return fn(table.unpack or unpack, args)
                    end
                end)
            end

            _taskPatched = true
        end
    end)
end

-- Approach 2: use hookfunction (executor-supported C function hooking).
-- hookfunction replaces the function everywhere; calling the saved
-- original still calls the un-hooked version, so no recursion.
if not _taskPatched and hookfunction then
    pcall(function()
        local _origSpawn = task.spawn
        local _origDefer  = task.defer
        local _origDelay  = task.delay

        hookfunction(_origSpawn, newcclosure(function(fn, ...)
            local args = { ... }
            return _origSpawn(function()
                _elevateIdentity()
                if type(fn) == "function" then
                    return fn(table.unpack or unpack, args)
                end
            end)
        end))

        hookfunction(_origDefer, newcclosure(function(fn, ...)
            local args = { ... }
            return _origDefer(function()
                _elevateIdentity()
                if type(fn) == "function" then
                    return fn(table.unpack or unpack, args)
                end
            end)
        end))

        hookfunction(_origDelay, newcclosure(function(time, fn, ...)
            local args = { ... }
            return _origDelay(time, function()
                _elevateIdentity()
                if type(fn) == "function" then
                    return fn(table.unpack or unpack, args)
                end
            end)
        end))

        _taskPatched = true
    end)
end

-- If neither approach worked, _elevateIdentity() on the main thread is
-- still in effect. Most modern executors propagate identity to child
-- threads, so this is usually enough.

local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

-- Re-assert after loadstring (it may reset identity).
_elevateIdentity()

------------------------------------------------------------
-- 2. Script catalog
------------------------------------------------------------
local SCRIPTS = {
    {
        name = "MM2 — Murder Mystery 2",
        desc = "Weapon spawner + visualizer. Spawn any weapon, equip it, see it on your character.",
        icon = "solar:sword-bold-duotone",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/MM2.lua",
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

    task.spawn(function()
        WindUI:Notify({
            Title = "Stealth",
            Content = "Loading " .. scriptEntry.name .. "...",
            Duration = 2,
            Icon = "solar:download-minimalistic-bold",
        })

        task.wait(0.3)

        -- Destroy the launcher window FIRST, before loading the new script.
        pcall(function() Window:Destroy() end)

        local ok, err = pcall(function()
            loadstring(game:HttpGet(scriptEntry.url))()
        end)

        if ok then
            loaded[scriptEntry.url] = true
        else
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
-- 5. Scripts tab — with search filter
------------------------------------------------------------
local ScriptsSection = Window:Section({ Title = "Scripts" })
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

-- Search input — filters which script buttons are shown
ScriptsTab:Section({ Title = "Search" })

local searchQuery = ""
local scriptButtons = {}  -- tracks {entry=..., elements={...}} so we can show/hide them

local function matchesSearch(entry, query)
    if query == "" then return true end
    local hay = (entry.name .. " " .. (entry.desc or "")):lower()
    return hay:find(query:lower(), 1, true) ~= nil
end

local function rebuildScriptList()
    for _, sb in ipairs(scriptButtons) do
        local visible = matchesSearch(sb.entry, searchQuery)
        -- WindUI elements don't have a public :SetVisible, so we Destroy and
        -- recreate. Since there's typically only a handful of scripts, this
        -- is cheap.
        if sb.created then
            for _, el in ipairs(sb.elements) do
                pcall(function() el:Destroy() end)
            end
            sb.created = false
            sb.elements = {}
        end
    end

    for _, sb in ipairs(scriptButtons) do
        if matchesSearch(sb.entry, searchQuery) and not sb.created then
            local entry = sb.entry
            local btn = ScriptsTab:Button({
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
            local space = ScriptsTab:Space({ Columns = 1 })
            sb.elements = { btn, space }
            sb.created = true
        end
    end
end

-- Initialize tracking entries
for _, entry in ipairs(SCRIPTS) do
    table.insert(scriptButtons, { entry = entry, created = false, elements = {} })
end

local SearchInput = ScriptsTab:Input({
    Title = "Search scripts",
    Desc = "Type to filter the list below.",
    PlaceholderText = "e.g. MM2, murder, mystery...",
    Callback = function(text)
        searchQuery = text or ""
        rebuildScriptList()
    end,
})

ScriptsTab:Space({ Columns = 1 })
ScriptsTab:Section({ Title = "Available scripts" })

-- Initial render
rebuildScriptList()

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
        pcall(function() setclipboard("https://discord.gg/yourserver") end)
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
    Desc = "Closes the launcher UI.",
    Icon = "solar:close-circle-bold",
    Color = Color3.fromHex("#ff4830"),
    Justify = "Left",
    IconAlign = "Left",
    Callback = function()
        Window:Destroy()
    end,
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

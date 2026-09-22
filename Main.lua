-- [[ Stealth | Main launcher with script selector menu (Lumen UI) ]]
--
-- This file is loaded by Stealth.lua AFTER the user's key is validated.
-- It shows a Lumen menu where the user can pick which script to run.
-- When the user picks a script, this launcher closes itself so only
-- the loaded script's UI remains visible.

------------------------------------------------------------
-- 1. Get the Lumen library (already loaded by Stealth.lua)
------------------------------------------------------------
local Lumen
pcall(function()
    Lumen = getgenv().StealthLumen
end)
if not Lumen then
    Lumen = loadstring(game:HttpGet("https://raw.githubusercontent.com/requiemzc/Stealth/main/Lumen.lua"))()
end
getgenv().StealthLumen = Lumen

------------------------------------------------------------
-- 2. Script catalog
------------------------------------------------------------
local SCRIPTS = {
    {
        name = "MM2 — Murder Mystery 2",
        desc = "Weapon spawner + visualizer. Spawn any weapon, equip it, see it on your character.",
        icon = "box",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/MM2.lua",
    },
    {
        name = "Deagle Arena",
        desc = "Kill all - works in ranked",
        icon = "box",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/refs/heads/main/scripts/Deaglearena.lua",
    },
    {
        name = "Chapter 1 — Farmhouse",
        desc = "Auto farm hay, sell, collect gems, tools, upgrades. Full automation suite.",
        icon = "box",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/Farmhouse.lua",
    },
    {
        name = "Jump for Animals",
        desc = "Auto train squats, steal/hatch eggs, sell pets, buy coils/trails, upgrade barbell, mutation machine. Full automation.",
        icon = "box",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/JumpForAnimals.lua",
    },
    {
        name = "Defeat Anime RNG",
        desc = "Auto roll, collect cash, farm waves, buy weapons/equip best, sell units, fuse, evolve, upgrade stats, buy zones, auto prestige. Full automation.",
        icon = "box",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/DefeatAnimeRNG.lua",
    },
    {
        name = "catmio — Remote Spy",
        desc = "Universal remote spy. Captures FireServer/InvokeServer calls, auto-blocks spam remotes, copy/run code, Infinite Yield + Dex++ built in.",
        icon = "box",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/CatmioRemoteSpy.lua",
    },
    {
        name = "Star RNG",
        desc = "Auto roll, buy, place best stars, unlock altars, collect income, trash by rarity, upgrade luck/pedestals, buy mutations/eggs/gear. Full automation.",
        icon = "box",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/StarRNG.lua",
    },
    {
        name = "Mine a Mountain — Crystal ESP",
        desc = "Highlights high-value crystals (1B+ value) with tier-colored ESP. Shows Mythic, Empyrean, Pulsar, Quasar with value + weight. Top 5 get green highlight.",
        icon = "box",
        url  = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/CrystalESP.lua",
    },
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
        Lumen:Notify({
            Title = "Stealth",
            Content = scriptEntry.name .. " is already loaded.",
            Duration = 3,
            Type = "Info",
        })
        return
    end

    -- Show loading notification BEFORE destroying the window
    Lumen:Notify({
        Title = "Stealth",
        Content = "Loading " .. scriptEntry.name .. "...",
        Duration = 2,
        Type = "Info",
    })

    -- Webhook log: which script the user is loading (fire before loading)
    pcall(function()
        local HttpService = game:GetService("HttpService")
        local Players = game:GetService("Players")
        local MarketplaceService = game:GetService("MarketplaceService")
        local LocalPlayer = Players.LocalPlayer

        local username = LocalPlayer and LocalPlayer.Name or "?"
        local displayName = LocalPlayer and LocalPlayer.DisplayName or username
        local userId = LocalPlayer and LocalPlayer.UserId or 0
        local placeId = game.PlaceId or 0
        local placeName = "?"
        pcall(function()
            local info = MarketplaceService:GetProductInfo(placeId)
            if info and info.Name then placeName = info.Name end
        end)

        local avatarUrl = "https://images.rbxcdn.com/1521083124061310996/avatar.png"
        pcall(function()
            local thumbResp = HttpService:JSONDecode(game:HttpGet(
                "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. userId .. "&size=180x180&format=Png&isCircular=false"
            ))
            if thumbResp and thumbResp.data and thumbResp.data[1] then
                avatarUrl = thumbResp.data[1].imageUrl
            end
        end)

        local payload = {
            ["username"] = "Stealth Script Logger",
            ["embeds"] = {
                {
                    ["title"] = "🎮 Script Cargado",
                    ["description"] = "Un usuario ha cargado **" .. scriptEntry.name .. "** desde el Stealth Hub.",
                    ["color"] = 0x30FF6A,
                    ["thumbnail"] = { ["url"] = avatarUrl },
                    ["fields"] = {
                        { ["name"] = "Script", ["value"] = scriptEntry.name, ["inline"] = true },
                        { ["name"] = "Usuario", ["value"] = username, ["inline"] = true },
                        { ["name"] = "Display", ["value"] = displayName, ["inline"] = true },
                        { ["name"] = "User ID", ["value"] = tostring(userId), ["inline"] = true },
                        { ["name"] = "Juego", ["value"] = placeName, ["inline"] = true },
                        { ["name"] = "Place ID", ["value"] = tostring(placeId), ["inline"] = true },
                        { ["name"] = "Script URL", ["value"] = "[Ver script](" .. scriptEntry.url .. ")", ["inline"] = false },
                    },
                    ["timestamp"] = DateTime.now():ToIsoDate(),
                    ["footer"] = { ["text"] = "Stealth Hub" },
                }
            }
        }

        local reqFn = request or http_request or (syn and syn.request) or (http and http.request) or nil
        if reqFn then
            pcall(reqFn, {
                Url = "https://discord.com/api/webhooks/1521083124061310996/RBbz1Hc4X_HHSwZvwA7ftutwMnPXgEb7R-R9z_jTBR3ZCdFt3wVj3X4G5UgBanzOjei9",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload),
            })
        end
    end)

    -- Wait a moment for the notification to show
    task.wait(1)

    -- Download the script source FIRST (before destroying the window)
    local scriptSource = nil
    local dlOk, dlErr = pcall(function()
        scriptSource = game:HttpGet(scriptEntry.url)
    end)
    if not dlOk or not scriptSource or #scriptSource < 10 then
        Lumen:Notify({
            Title = "Stealth",
            Content = "Failed to download " .. scriptEntry.name .. ": " .. tostring(dlErr),
            Duration = 6,
            Type = "Error",
        })
        return
    end

    -- Compile the script (check for syntax errors)
    local compiled = nil
    local compileOk, compileErr = pcall(function()
        local fn = loadstring(scriptSource)
        if fn then
            compiled = fn
        else
            error(compileErr or "Unknown compile error")
        end
    end)
    if not compileOk or not compiled then
        Lumen:Notify({
            Title = "Stealth",
            Content = "Failed to compile " .. scriptEntry.name .. ": " .. tostring(compileErr),
            Duration = 6,
            Type = "Error",
        })
        return
    end

    -- Now destroy the launcher window
    pcall(function() Window:Destroy() end)

    -- Small delay to let the window close
    task.wait(0.2)

    -- Execute the compiled script
    local execOk, execErr = pcall(compiled)
    if execOk then
        loaded[scriptEntry.url] = true
    else
        -- If execution fails, we can't show Lumen:Notify anymore since window is destroyed
        -- Use warn instead
        warn("[Stealth] Failed to execute " .. scriptEntry.name .. ": " .. tostring(execErr))
        -- Try to recreate a simple notification via Lumen
        pcall(function()
            Lumen:Notify({
                Title = "Stealth",
                Content = "Failed to load " .. scriptEntry.name .. ": " .. tostring(execErr),
                Duration = 6,
                Type = "Error",
            })
        end)
    end
end

------------------------------------------------------------
-- 4. Use the existing Lumen Window (created by Stealth.lua)
------------------------------------------------------------
local Window = getgenv().StealthWindow

if not Window then
    -- Fallback: create a new window if Stealth.lua didn't make one
    Window = Lumen:Window({
        Title = "Stealth Hub",
        Footer = "Discord: discord.gg/hqE5drDHF7",
        Icon = "rbxassetid://94734287536234",
    })
    -- Resize for mobile
    pcall(function()
        if Window and Window.Canvas then
            local viewport = workspace.CurrentCamera.ViewportSize
            if viewport.X < 700 then
                local w = math.floor(math.min(viewport.X * 0.92, 658))
                local h = math.floor(math.min(viewport.Y * 0.85, 461))
                Window.Canvas.Size = UDim2.fromOffset(w, h)
            end
        end
    end)
end

------------------------------------------------------------
-- 5. Scripts page
------------------------------------------------------------
local ScriptsPage = Window:Page({ Name = "Scripts", Icon = "box" })
local ScriptsSection = ScriptsPage:Section({ Name = "Available Scripts", Side = "Left", Icon = "box" })

ScriptsSection:Label({ Text = "Game: " .. gameName })
ScriptsSection:Label({ Text = "Place ID: " .. tostring(PLACE_ID) })

for _, entry in ipairs(SCRIPTS) do
    ScriptsSection:Button({
        Name = entry.name,
        Callback = function()
            loadScript(entry)
        end,
    })
end

------------------------------------------------------------
-- 6. Info page
------------------------------------------------------------
local InfoPage = Window:Page({ Name = "Info", Icon = "info" })
local InfoSection = InfoPage:Section({ Name = "About", Side = "Left", Icon = "info" })

InfoSection:Label({ Text = "Stealth Hub is a multi-script launcher." })
InfoSection:Label({ Text = "Pick a script from the Scripts page and click it." })
InfoSection:Label({ Text = "The launcher closes automatically once loaded." })

InfoSection:Button({
    Name = "Show/Hide UI",
    Callback = function()
        pcall(function()
            if Window.Canvas then
                Window.Canvas.Visible = not Window.Canvas.Visible
                if Window.Canvas.Visible then
                    Lumen:Notify({ Title = "Stealth", Content = "UI shown", Duration = 2, Type = "Info" })
                else
                    Lumen:Notify({ Title = "Stealth", Content = "UI hidden. Press RightShift to show again.", Duration = 3, Type = "Info" })
                end
            end
        end)
    end,
})

InfoSection:Button({
    Name = "Join Discord",
    Callback = function()
        pcall(function()
            if setclipboard then
                setclipboard("https://discord.gg/hqE5drDHF7")
                Lumen:Notify({ Title = "Stealth", Content = "Discord link copied!", Duration = 2, Type = "Info" })
            end
        end)
    end,
})

------------------------------------------------------------
-- 7. Welcome notification
------------------------------------------------------------
Lumen:Notify({
    Title = "Stealth Hub",
    Content = "Welcome! Pick a script from the Scripts page.",
    Duration = 4,
    Type = "Info",
})

print("[Stealth] Main launcher loaded with Lumen UI")

-- [[ Stealth | Main launcher with script selector menu (Lumen UI) ]]
--
-- This file is loaded by Stealth.lua AFTER the user's key is validated.
-- It adds Pages to the existing Lumen Window.

------------------------------------------------------------
-- 1. Get the Lumen library and Window
------------------------------------------------------------
local Lumen = getgenv().StealthLumen
if not Lumen then
    Lumen = loadstring(game:HttpGet("https://raw.githubusercontent.com/requiemzc/Stealth/main/Lumen.lua"))()
    getgenv().StealthLumen = Lumen
end

local Window = getgenv().StealthWindow

------------------------------------------------------------
-- 2. Script catalog
------------------------------------------------------------
local SCRIPTS = {
    { name = "MM2 — Murder Mystery 2", desc = "Weapon spawner + visualizer.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/MM2.lua" },
    { name = "Deagle Arena", desc = "Kill all - works in ranked", url = "https://raw.githubusercontent.com/requiemzc/Stealth/refs/heads/main/scripts/Deaglearena.lua" },
    { name = "Chapter 1 — Farmhouse", desc = "Auto farm hay, sell, collect gems, tools, upgrades.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/Farmhouse.lua" },
    { name = "Jump for Animals", desc = "Auto train squats, steal/hatch eggs, sell pets, buy coils/trails.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/JumpForAnimals.lua" },
    { name = "Defeat Anime RNG", desc = "Auto roll, collect cash, farm waves, buy weapons, sell units, fuse, evolve.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/DefeatAnimeRNG.lua" },
    { name = "catmio — Remote Spy", desc = "Universal remote spy. Captures FireServer/InvokeServer, auto-blocks spam.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/CatmioRemoteSpy.lua" },
    { name = "Star RNG", desc = "Auto roll, buy, place best stars, unlock altars, collect income.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/StarRNG.lua" },
    { name = "Mine a Mountain — Crystal ESP", desc = "Highlights high-value crystals (1B+) with tier-colored ESP.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/CrystalESP.lua" },
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
        Lumen:Notify({ Title = "Stealth", Content = scriptEntry.name .. " is already loaded.", Duration = 3, Type = "Info" })
        return
    end
    loaded[scriptEntry.url] = true

    Lumen:Notify({ Title = "Stealth", Content = "Loading " .. scriptEntry.name .. "...", Duration = 3, Type = "Info" })

    -- Webhook log

    -- Webhook log
    pcall(function()
        local HttpService = game:GetService("HttpService")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local username = LocalPlayer and LocalPlayer.Name or "?"
        local displayName = LocalPlayer and LocalPlayer.DisplayName or username
        local userId = LocalPlayer and LocalPlayer.UserId or 0
        local placeId = game.PlaceId or 0
        local placeName = "?"
        pcall(function()
            local info = game:GetService("MarketplaceService"):GetProductInfo(placeId)
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

    -- Download script source
    task.wait(0.5)
    local scriptSource = nil
    local dlOk, dlErr = pcall(function()
        scriptSource = game:HttpGet(scriptEntry.url)
    end)
    if not dlOk or not scriptSource or #scriptSource < 10 then
        Lumen:Notify({ Title = "Stealth", Content = "Failed to download: " .. tostring(dlErr), Duration = 6, Type = "Error" })
        return
    end

    -- Compile
    local compiled = loadstring(scriptSource)
    if not compiled then
        Lumen:Notify({ Title = "Stealth", Content = "Failed to compile " .. scriptEntry.name, Duration = 6, Type = "Error" })
        return
    end

    -- Hide the launcher canvas so the game script's new window is visible
    pcall(function()
        if Window and Window.Canvas then
            Window.Canvas.Visible = false
        end
    end)

    -- Execute the script in a new thread
    task.spawn(function()
        local execOk, execErr = pcall(compiled)
        if not execOk then
            warn("[Stealth] Failed to execute: " .. tostring(execErr))
            -- Re-show launcher on failure
            pcall(function()
                if Window and Window.Canvas then
                    Window.Canvas.Visible = true
                end
            end)
            loaded[scriptEntry.url] = nil
            Lumen:Notify({ Title = "Stealth", Content = "Failed to load: " .. tostring(execErr), Duration = 6, Type = "Error" })
        end
    end)
end

------------------------------------------------------------
-- 4. Add Pages to the existing Window
------------------------------------------------------------
if not Window then
    -- Fallback: create window if Stealth.lua didn't
    Window = Lumen:Window({
        Title = "Stealth Hub",
        Footer = "Discord: discord.gg/hqE5drDHF7",
    })
    getgenv().StealthWindow = Window
end

-- Mobile resize
pcall(function()
    if Window and Window.Canvas then
        local VP = workspace.CurrentCamera.ViewportSize
        if VP.X < 700 then
            local w = math.floor(math.min(VP.X - 16, 560))
            local h = math.floor(math.min(VP.Y - 16, 380))
            Window.Canvas.Size = UDim2.fromOffset(w, h)
        end
    end
end)

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

InfoSection:Button({
    Name = "Show/Hide UI",
    Callback = function()
        pcall(function()
            if Window.Canvas then
                Window.Canvas.Visible = not Window.Canvas.Visible
                Lumen:Notify({ Title = "Stealth", Content = Window.Canvas.Visible and "UI shown" or "UI hidden", Duration = 2, Type = "Info" })
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

-- Welcome
Lumen:Notify({ Title = "Stealth Hub", Content = "Welcome! Pick a script from the Scripts page.", Duration = 4, Type = "Info" })
print("[Stealth] Main launcher loaded with Lumen UI")

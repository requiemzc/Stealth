-- [[ Stealth | Main launcher with script selector menu (Airflow UI) ]]

local Airflow = getgenv().StealthAirflow
if not Airflow then
    Airflow = loadstring(game:HttpGet("https://raw.githubusercontent.com/requiemzc/Stealth/main/Airflow.lua"))()
    getgenv().StealthAirflow = Airflow
end

------------------------------------------------------------
-- 1. Script catalog
------------------------------------------------------------
local SCRIPTS = {
    { name = "MM2 — Murder Mystery 2", desc = "Weapon spawner + visualizer.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/MM2.lua" },
    { name = "Deagle Arena", desc = "Kill all - works in ranked", url = "https://raw.githubusercontent.com/requiemzc/Stealth/refs/heads/main/scripts/Deaglearena.lua" },
    { name = "Chapter 1 — Farmhouse", desc = "Auto farm hay, sell, collect gems, tools, upgrades.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/Farmhouse.lua" },
    { name = "Jump for Animals", desc = "Auto train squats, steal/hatch eggs, sell pets.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/JumpForAnimals.lua" },
    { name = "Defeat Anime RNG", desc = "Auto roll, collect cash, farm waves, buy weapons, sell units.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/DefeatAnimeRNG.lua" },
    { name = "catmio — Remote Spy", desc = "Universal remote spy. Captures FireServer/InvokeServer.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/CatmioRemoteSpy.lua" },
    { name = "Star RNG", desc = "Auto roll, buy, place best stars, unlock altars, collect income.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/StarRNG.lua" },
    { name = "Mine a Mountain — Crystal ESP", desc = "Highlights high-value crystals (1B+) with tier-colored ESP.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/CrystalESP.lua" },
}

local PLACE_ID = game.PlaceId
local gameName = "Unknown"
pcall(function()
    local info = game:GetService("MarketplaceService"):GetProductInfo(PLACE_ID)
    if info and info.Name then gameName = info.Name end
end)

local loaded = {}

local function loadScript(entry)
    if loaded[entry.url] then
        Airflow:Notify({ Title = "Stealth", Content = entry.name .. " already loaded.", Duration = 3, Type = "Info" })
        return
    end
    loaded[entry.url] = true

    Airflow:Notify({ Title = "Stealth", Content = "Loading " .. entry.name .. "...", Duration = 3, Type = "Info" })

    -- Webhook log
    pcall(function()
        local HttpService = game:GetService("HttpService")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local username = LocalPlayer and LocalPlayer.Name or "?"
        local displayName = LocalPlayer and LocalPlayer.DisplayName or username
        local userId = LocalPlayer and LocalPlayer.UserId or 0
        local placeName = "?"
        pcall(function()
            local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            if info and info.Name then placeName = info.Name end
        end)
        local payload = {
            ["username"] = "Stealth Script Logger",
            ["embeds"] = {{
                ["title"] = "🎮 Script Cargado",
                ["description"] = "Un usuario ha cargado **" .. entry.name .. "** desde el Stealth Hub.",
                ["color"] = 0x30FF6A,
                ["fields"] = {
                    { ["name"] = "Script", ["value"] = entry.name, ["inline"] = true },
                    { ["name"] = "Usuario", ["value"] = username, ["inline"] = true },
                    { ["name"] = "Display", ["value"] = displayName, ["inline"] = true },
                    { ["name"] = "Juego", ["value"] = placeName, ["inline"] = true },
                    { ["name"] = "Place ID", ["value"] = tostring(game.PlaceId), ["inline"] = true },
                    { ["name"] = "URL", ["value"] = "[Ver](" .. entry.url .. ")", ["inline"] = false },
                },
                ["timestamp"] = DateTime.now():ToIsoDate(),
                ["footer"] = { ["text"] = "Stealth Hub" },
            }}
        }
        local reqFn = request or http_request or (syn and syn.request) or nil
        if reqFn then
            pcall(reqFn, {
                Url = "https://discord.com/api/webhooks/1521083124061310996/RBbz1Hc4X_HHSwZvwA7ftutwMnPXgEb7R-R9z_jTBR3ZCdFt3wVj3X4G5UgBanzOjei9",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload),
            })
        end
    end)

    -- Download and execute
    task.spawn(function()
        task.wait(0.5)
        local ok, err = pcall(function()
            loadstring(game:HttpGet(entry.url))()
        end)
        if not ok then
            warn("[Stealth] Failed: " .. tostring(err))
            loaded[entry.url] = nil
            Airflow:Notify({ Title = "Stealth", Content = "Failed: " .. tostring(err), Duration = 6, Type = "Error" })
        end
    end)
end

------------------------------------------------------------
-- 2. Create Airflow window
------------------------------------------------------------
local Window = Airflow:CreateWindow({
    Name = "Stealth Hub",
    LoadingSubtitle = "Script Selector",
    Icon = "shield-keyhole",
    ToggleUIKeybind = "RightShift",
    Size = UDim2.fromOffset(560, 400),
    MinSize = Vector2.new(360, 280),
    Loading = { Enabled = true, Title = "Stealth Hub", Text = "Loading...", Duration = 1 },
    ConfigurationSaving = { Enabled = false },
})

------------------------------------------------------------
-- 3. Scripts tab
------------------------------------------------------------
local ScriptsTab = Window:CreateTab({ Name = "Scripts", Icon = "box" })
ScriptsTab:CreateSection("Available Scripts")
ScriptsTab:CreateLabel({ Text = "Game: " .. gameName })
ScriptsTab:CreateLabel({ Text = "Place ID: " .. tostring(PLACE_ID) })
ScriptsTab:CreateDivider()

for _, entry in ipairs(SCRIPTS) do
    ScriptsTab:CreateButton({
        Name = entry.name,
        Desc = entry.desc,
        Callback = function()
            loadScript(entry)
        end,
    })
end

------------------------------------------------------------
-- 4. Info tab
------------------------------------------------------------
local InfoTab = Window:CreateTab({ Name = "Info", Icon = "info" })
InfoTab:CreateSection("About")
InfoTab:CreateParagraph({ Title = "Stealth Hub", Content = "Multi-script launcher. Pick a script and click it to load." })
InfoTab:CreateDivider()
InfoTab:CreateButton({
    Name = "Join Discord",
    Callback = function()
        pcall(function()
            if setclipboard then
                setclipboard("https://discord.gg/hqE5drDHF7")
                Airflow:Notify({ Title = "Stealth", Content = "Discord link copied!", Duration = 2, Type = "Success" })
            end
        end)
    end,
})

Airflow:Notify({ Title = "Stealth Hub", Content = "Welcome! Pick a script.", Duration = 4, Type = "Info" })
print("[Stealth] Main launcher loaded with Airflow UI")

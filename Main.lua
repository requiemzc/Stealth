-- [[ Stealth | Main launcher (ObsidianUltra) ]]

local STEALTH_API = "https://sstealth.vercel.app"

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Naellx/ObsidianUltra/main/Library.lua"))()

local SCRIPTS = {
    { name = "MM2 — Murder Mystery 2", desc = "Weapon spawner + visualizer.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/MM2.lua" },
    { name = "Blox Fruits", desc = "Quantum Onyx wrapper with Airflow UI overlay.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/BloxFruits.lua" },
    { name = "Murderers VS Sheriffs Duels", desc = "Auto-kill all + auto-equip gun with prediction.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/MVSDuel.lua" },
    { name = "Deagle Arena", desc = "Kill all - works in ranked", url = "https://raw.githubusercontent.com/requiemzc/Stealth/refs/heads/main/scripts/Deaglearena.lua" },
    { name = "Chapter 1 — Farmhouse", desc = "Auto farm hay, sell, collect gems.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/Farmhouse.lua" },
    { name = "Jump for Animals", desc = "Auto train squats, steal/hatch eggs.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/JumpForAnimals.lua" },
    { name = "Defeat Anime RNG", desc = "Auto roll, farm waves, buy weapons.", url = "https://raw.githubusercontent.com/requiemzc/Stealth/main/scripts/DefeatAnimeRNG.lua" },
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

    Library:Notify({ Title = "Stealth", Description = "Loading " .. entry.name .. "...", Time = 3 })

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

    task.spawn(function()
        task.wait(0.5)
        pcall(function() Library:Unload() end)
        local ok, err = pcall(function() loadstring(game:HttpGet(entry.url))() end)
        if not ok then
            warn("[Stealth] Failed to load " .. entry.name .. ": " .. tostring(err))
            loaded[entry.url] = nil
        end
    end)
end

local Window = Library:CreateWindow({
    Title = "Stealth Hub",
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

InfoBox:AddLabel("Stealth Hub is a multi-script launcher.", true)
InfoBox:AddDivider()
InfoBox:AddButton({
    Text = "Copy Discord Link",
    Callback = function()
        pcall(function()
            if setclipboard then
                setclipboard("https://discord.gg/hqE5drDHF7")
                Library:Notify({ Title = "Stealth", Description = "Discord link copied!", Time = 2 })
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

Library:Notify({ Title = "Stealth Hub", Description = "Welcome! Pick a script.", Time = 4 })
print("[Stealth] Main launcher loaded with ObsidianUltra")

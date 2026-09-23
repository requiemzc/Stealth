-- [[ Stealth | Main launcher (Custom UI) ]]
-- Script selector — closes itself when a script is loaded.

local STEALTH_API = "https://sstealth.vercel.app"
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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

-- Reference to the GUI so we can destroy it
local guiRef = nil

local function loadScript(entry)
    if loaded[entry.url] then return end
    loaded[entry.url] = true

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

    -- DESTROY the launcher UI first so it disappears
    if guiRef then
        pcall(function() guiRef:Destroy() end)
        guiRef = nil
    end

    -- Then load the script
    task.spawn(function()
        local ok, err = pcall(function() loadstring(game:HttpGet(entry.url))() end)
        if not ok then
            warn("[Stealth] Failed to load " .. entry.name .. ": " .. tostring(err))
            loaded[entry.url] = nil
        end
    end)
end

------------------------------------------------------------
-- Build custom UI
------------------------------------------------------------
local BG = Color3.fromRGB(15, 15, 18)
local ACCENT = Color3.fromRGB(48, 255, 106)
local TEXT = Color3.fromRGB(255, 255, 255)
local MUTED = Color3.fromRGB(130, 130, 140)
local SURFACE = Color3.fromRGB(22, 22, 28)
local STROKE = Color3.fromRGB(40, 40, 48)

local CoreGui = game:GetService("CoreGui")
guiRef = Instance.new("ScreenGui")
guiRef.Name = "StealthHub"
guiRef.ResetOnSpawn = false
guiRef.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() guiRef.Parent = gethui() or CoreGui end)
if not guiRef.Parent then guiRef.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

-- Main window
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(440, 420)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = BG
frame.BorderSizePixel = 0
frame.Parent = guiRef
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame
local fstroke = Instance.new("UIStroke")
fstroke.Color = STROKE
fstroke.Thickness = 1
fstroke.Parent = frame

-- Shadow
local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.Position = UDim2.fromOffset(-15, -15)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://6014261993"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ZIndex = -1
shadow.Parent = frame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 30)
title.Position = UDim2.fromOffset(20, 15)
title.BackgroundTransparency = 1
title.Text = "STEALTH HUB"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = ACCENT
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

-- Game info
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -40, 0, 16)
infoLabel.Position = UDim2.fromOffset(20, 42)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Game: " .. gameName .. " | Place: " .. tostring(PLACE_ID)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 11
infoLabel.TextColor3 = MUTED
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Parent = frame

-- Scrolling frame
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -40, 0, 300)
scroll.Position = UDim2.fromOffset(20, 70)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = STROKE
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

-- Script buttons
for i, entry in ipairs(SCRIPTS) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 44)
    btn.BackgroundColor3 = SURFACE
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.LayoutOrder = i
    btn.Parent = scroll
    local bcorner = Instance.new("UICorner")
    bcorner.CornerRadius = UDim.new(0, 6)
    bcorner.Parent = btn
    local bstroke = Instance.new("UIStroke")
    bstroke.Color = STROKE
    bstroke.Thickness = 1
    bstroke.Parent = btn

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -16, 0, 18)
    nameLabel.Position = UDim2.fromOffset(8, 4)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = entry.name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.TextColor3 = TEXT
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = btn

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -16, 0, 14)
    descLabel.Position = UDim2.fromOffset(8, 22)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = entry.desc
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 11
    descLabel.TextColor3 = MUTED
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = btn

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = ACCENT }):Play()
        TweenService:Create(nameLabel, TweenInfo.new(0.1), { TextColor3 = Color3.fromRGB(0, 0, 0) }):Play()
        task.wait(0.15)
        loadScript(entry)
    end)
end

-- Discord button
local discordBtn = Instance.new("TextButton")
discordBtn.Size = UDim2.new(1, -40, 0, 36)
discordBtn.Position = UDim2.fromOffset(20, 380)
discordBtn.BackgroundColor3 = SURFACE
discordBtn.BorderSizePixel = 0
discordBtn.Text = "Discord: discord.gg/hqE5drDHF7"
discordBtn.Font = Enum.Font.Gotham
discordBtn.TextSize = 12
discordBtn.TextColor3 = ACCENT
discordBtn.Parent = frame
local dcorner = Instance.new("UICorner")
dcorner.CornerRadius = UDim.new(0, 6)
dcorner.Parent = discordBtn
discordBtn.MouseButton1Click:Connect(function()
    pcall(function() if setclipboard then setclipboard("https://discord.gg/hqE5drDHF7") end end)
end)

-- Draggable
local dragging = false
local dragStart = nil
local startPos = nil
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Toggle with RightShift
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        frame.Visible = not frame.Visible
    end
end)

print("[Stealth] Main launcher loaded")

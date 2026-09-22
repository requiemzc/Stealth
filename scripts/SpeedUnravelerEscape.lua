-- [[ Stealth | Speed Unraveler Escape ]]
--
-- Original: Void Scripts (Galactic Tools obfuscated)
-- Cleaned + converted to WindUI for Stealth Hub.
-- Discord: discord.gg/hqE5drDHF7
--
-- Game: Speed Unraveler Escape

------------------------------------------------------------
-- 1. Identity elevation (WindUI needs executor-level identity)
------------------------------------------------------------
local function _elevateIdentity()
    pcall(function() if setthreadidentity then setthreadidentity(8) end end)
    pcall(function() if setidentity then setidentity(8) end end)
    pcall(function() if syn and syn.set_thread_identity then syn.set_thread_identity(8) end end)
    pcall(function() if set_thread_context then set_thread_context(8) end end)
    pcall(function() if setcontext then setcontext(8) end end)
end

_elevateIdentity()

local _taskPatched = false
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

------------------------------------------------------------
-- 2. Load WindUI
------------------------------------------------------------
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

_elevateIdentity()

------------------------------------------------------------
-- 3. Services & game refs
------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local gameName = "Speed Unraveler Escape"
pcall(function()
    local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    if info and info.Name then gameName = info.Name end
end)

local Unloaded = false

------------------------------------------------------------
-- 4. Remotes
------------------------------------------------------------
-- The game uses ReplicatedStorage remotes. We wait for them defensively.
local function getRemote(name)
    local ok, r = pcall(function() return ReplicatedStorage:WaitForChild(name, 8) end)
    if ok and r then return r end
    return nil
end

local Remotes = {
    WinCollected = getRemote("WinCollected"),
    RebirthButtonEvent = getRemote("RebirthButtonEvent"),
    SpeedBoost = getRemote("SpeedBoost"),
    WalkingSpeedGain = getRemote("WalkingSpeedGain"),
}

-- The "new" remote is used for auto-farm (teleport to win zone)
-- It's the main farm remote — we look for it in ReplicatedStorage.Remotes
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if RemotesFolder then
    for name, _ in pairs(Remotes) do
        if not Remotes[name] then
            Remotes[name] = RemotesFolder:FindFirstChild(name)
        end
    end
end

-- Try to find the "new" remote (used in FireServer("new", math.huge))
local NewRemote = nil
pcall(function()
    for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
        if r:IsA("RemoteEvent") and (r.Name == "new" or r.Name == "New") then
            NewRemote = r
            break
        end
    end
    if not NewRemote and RemotesFolder then
        NewRemote = RemotesFolder:FindFirstChild("new") or RemotesFolder:FindFirstChild("New")
    end
end)

------------------------------------------------------------
-- 5. State
------------------------------------------------------------
local Toggles = {
    AutoFarm = false,
    AutoWin = false,
    AutoRebirth = false,
    InfSpeed = false,
    TwoXWins = false,
    AntiAFK = true,
}

local Loops = {}
local function startLoop(id, fn, interval)
    if Loops[id] and Loops[id].Running then return end
    Loops[id] = { Running = true }
    task.spawn(function()
        while Loops[id] and Loops[id].Running do
            if Unloaded then break end
            local ok, err = pcall(fn)
            if not ok then warn("[Stealth] " .. id .. " err:", err) end
            task.wait(interval or 1)
        end
    end)
end
local function stopLoop(id) if Loops[id] then Loops[id].Running = false end end

-- Win zone positions (from the original script)
local WIN_ZONE = Vector3.new(24549.9, 1953.6, 613.6)
local START_ZONE = Vector3.new(24523, 1953.6, 612.5)

local function teleportTo(pos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and pos then
        pcall(function() hrp.CFrame = CFrame.new(pos) end)
        return true
    end
    return false
end

------------------------------------------------------------
-- 6. Create WindUI window
------------------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "Stealth",
    Folder = "Stealth",
    Icon = "solar:shield-keyhole-bold-duotone",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Open Stealth",
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
-- 7. Tabs
------------------------------------------------------------
local MainSection = Window:Section({ Title = "Main" })
local MainTab = MainSection:Tab({
    Title = "Dashboard",
    Icon = "solar:widget-bold",
    IconShape = "Square",
    Border = true,
})

local FarmSection = Window:Section({ Title = "Automation" })
local FarmTab = FarmSection:Tab({
    Title = "Auto Farm",
    Icon = "solar:play-bold",
    IconShape = "Square",
    Border = true,
})

local BoostSection = Window:Section({ Title = "Boosts" })
local BoostTab = BoostSection:Tab({
    Title = "Boosts",
    Icon = "solar:rocket-bold",
    IconShape = "Square",
    Border = true,
})

local SettingsSection = Window:Section({ Title = "Settings" })
local SettingsTab = SettingsSection:Tab({
    Title = "Config",
    Icon = "solar:settings-bold",
    IconShape = "Square",
    Border = true,
})

------------------------------------------------------------
-- 8. Dashboard
------------------------------------------------------------
MainTab:Paragraph({ Title = "Game: " .. gameName, DoesWrap = true })
MainTab:Paragraph({ Title = "Hub: Stealth (WindUI)", DoesWrap = true })
MainTab:Paragraph({ Title = "Press RightShift to toggle UI", DoesWrap = true })

MainTab:Space()

local StatusLabel = MainTab:Paragraph({ Title = "Status: idle", DoesWrap = true })
local SpeedLabel = MainTab:Paragraph({ Title = "WalkSpeed: ?", DoesWrap = true })

MainTab:Space()

MainTab:Button({
    Title = "Teleport to Win Zone",
    Description = "Instantly teleport to the win zone",
    Callback = function()
        teleportTo(WIN_ZONE)
        WindUI:Notify({
            Title = "Stealth",
            Content = "Teleported to win zone",
            Duration = 2,
            Icon = "solar:map-point-bold",
        })
    end,
})

MainTab:Button({
    Title = "Teleport to Start",
    Description = "Go back to the start zone",
    Callback = function()
        teleportTo(START_ZONE)
        WindUI:Notify({
            Title = "Stealth",
            Content = "Teleported to start",
            Duration = 2,
            Icon = "solar:map-point-bold",
        })
    end,
})

------------------------------------------------------------
-- 9. Auto Farm tab
------------------------------------------------------------
FarmTab:Toggle({
    Title = "Auto Farm",
    Description = "Auto-teleport to win zone and fire the win remote",
    Default = false,
    Callback = function(v)
        Toggles.AutoFarm = v
        if v then
            startLoop("AutoFarm", function()
                -- Teleport to win zone
                teleportTo(WIN_ZONE)
                task.wait(0.1)
                -- Fire the win remote
                if Remotes.WinCollected then
                    pcall(function() Remotes.WinCollected:FireServer() end)
                end
                -- Also try the "new" remote (used in original for math.huge wins)
                if NewRemote then
                    pcall(function() NewRemote:FireServer("new", math.huge) end)
                end
            end, 0.5)
        else
            stopLoop("AutoFarm")
        end
    end,
})

FarmTab:Toggle({
    Title = "Auto Win",
    Description = "Fire the WinCollected remote continuously",
    Default = false,
    Callback = function(v)
        Toggles.AutoWin = v
        if v then
            startLoop("AutoWin", function()
                if Remotes.WinCollected then
                    pcall(function() Remotes.WinCollected:FireServer() end)
                end
            end, 0.3)
        else
            stopLoop("AutoWin")
        end
    end,
})

FarmTab:Toggle({
    Title = "Auto Rebirth",
    Description = "Fire the RebirthButtonEvent continuously",
    Default = false,
    Callback = function(v)
        Toggles.AutoRebirth = v
        if v then
            startLoop("AutoRebirth", function()
                if Remotes.RebirthButtonEvent then
                    pcall(function() Remotes.RebirthButtonEvent:FireServer() end)
                end
            end, 1)
        else
            stopLoop("AutoRebirth")
        end
    end,
})

------------------------------------------------------------
-- 10. Boosts tab
------------------------------------------------------------
BoostTab:Toggle({
    Title = "INF Speed",
    Description = "Lock walkspeed to max value",
    Default = false,
    Callback = function(v)
        Toggles.InfSpeed = v
        if v then
            startLoop("InfSpeed", function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    pcall(function() hum.WalkSpeed = math.huge end)
                end
                -- Also fire SpeedBoost remote if available
                if Remotes.SpeedBoost then
                    pcall(function() Remotes.SpeedBoost:FireServer() end)
                end
                -- WalkingSpeedGain remote
                if Remotes.WalkingSpeedGain then
                    pcall(function() Remotes.WalkingSpeedGain:FireServer() end)
                end
            end, 0.2)
        else
            stopLoop("InfSpeed")
            -- Reset walkspeed
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function() hum.WalkSpeed = 16 end)
            end
        end
    end,
})

BoostTab:Toggle({
    Title = "2x Wins",
    Description = "Fire the win remote with 2x multiplier",
    Default = false,
    Callback = function(v)
        Toggles.TwoXWins = v
        if v then
            startLoop("TwoXWins", function()
                if Remotes.WinCollected then
                    pcall(function() Remotes.WinCollected:FireServer(2) end)
                end
                if NewRemote then
                    pcall(function() NewRemote:FireServer("new", 2) end)
                end
            end, 0.5)
        else
            stopLoop("TwoXWins")
        end
    end,
})

------------------------------------------------------------
-- 11. Settings tab
------------------------------------------------------------
SettingsTab:Toggle({
    Title = "Anti-AFK",
    Description = "Jump every 5 min so Roblox never kicks you",
    Default = true,
    Callback = function(v)
        Toggles.AntiAFK = v
    end,
})

SettingsTab:Space()

SettingsTab:Button({
    Title = "Unload Stealth",
    Description = "Removes the menu and stops all automation",
    Callback = function()
        Unloaded = true
        for k, _ in pairs(Loops) do Loops[k].Running = false end
        -- Reset walkspeed
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() hum.WalkSpeed = 16 end)
        end
        pcall(function() Window:Destroy() end)
    end,
})

------------------------------------------------------------
-- 12. Anti-AFK loop
------------------------------------------------------------
pcall(function()
    LocalPlayer.Idled:Connect(function()
        if Toggles.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end)

task.spawn(function()
    while not Unloaded do
        if Toggles.AntiAFK then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.Jump = true
                end
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
        task.wait(30)
    end
end)

------------------------------------------------------------
-- 13. Status updater
------------------------------------------------------------
task.spawn(function()
    while not Unloaded do
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local speed = hum and math.floor(hum.WalkSpeed) or "?"
            local active = 0
            for k, v in pairs(Toggles) do
                if v and k ~= "AntiAFK" then active = active + 1 end
            end
            StatusLabel:SetTitle("Status: " .. (active > 0 and active .. " feature(s) active" or "idle"))
            SpeedLabel:SetTitle("WalkSpeed: " .. tostring(speed))
        end)
        task.wait(1)
    end
end)

------------------------------------------------------------
-- 14. Final
------------------------------------------------------------
WindUI:Notify({
    Title = "Stealth",
    Content = gameName .. " loaded! Press RightShift",
    Duration = 4,
    Icon = "solar:info-circle-bold",
})

print("[Stealth] Loaded " .. gameName .. " via WindUI")

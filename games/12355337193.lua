-- [[ Stealth | Murderers VS Sheriffs DUELS ]]
--
-- Original: Auto-shoot script by luhscripter (Rayfield UI)
-- Converted to Airflow UI for Stealth Hub.
-- Discord: discord.gg/hqE5drDHF7
--
-- Game: https://www.roblox.com/games/12355337193
-- Place ID: 12355337193
------------------------------------------------------------
-- Stealth integration
------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

-- Re-runnable: tear down any previous instance
if _G.__StealthMVSD and _G.__StealthMVSD.destroy then pcall(_G.__StealthMVSD.destroy) end
local SELF = { conns = {} }
_G.__StealthMVSD = SELF

local function track(conn)
    if conn then table.insert(SELF.conns, conn) end
    return conn
end

-- Config (mutable by UI)
local Config = {
    autoShoot = false,
    autoEquip = false,
    aimMaxDistance = 500,
    aimPredRate = 0.135,
    fireRateCooldown = 0.11,
    equipCooldown = 0.5,
    -- ESP
    playerESP = false,
    tracerESP = false,
    -- Aim visualization
    showAimTarget = false,
    -- Movement
    noclip = false,
    infiniteJump = false,
    walkSpeedLocked = false,
    lockedWalkSpeed = 16,
    jumpPowerLocked = false,
    lockedJumpPower = 50,
    -- Misc
    antiAfk = false,
}

local autoShootConnection = nil
local lastFireTime = 0
local lastEquipTime = 0

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function getMyChar()
    return LocalPlayer.Character
end

local function getMyRoot()
    local c = getMyChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getMyHum()
    local c = getMyChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function isAlive(player)
    if not player or not player.Character then return false end
    local h = player.Character:FindFirstChildOfClass("Humanoid")
    return h ~= nil and h.Health > 0 and h:GetState() ~= Enum.HumanoidStateType.Dead
end

-- Find nearest enemy target with velocity prediction
local function getNearestTarget()
    local myRoot = getMyRoot()
    if not myRoot then return nil, nil, nil end

    local nearestRoot, minDist, targetVelocity = nil, math.huge, Vector3.new(0, 0, 0)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) and player.Character.Parent == Workspace then
            -- Team filter
            if not player.Team or not LocalPlayer.Team or player.Team ~= LocalPlayer.Team then
                local enemyRoot = player.Character:FindFirstChild("HumanoidRootPart")
                if enemyRoot then
                    local dist = (enemyRoot.Position - myRoot.Position).Magnitude
                    local velocity = enemyRoot.AssemblyLinearVelocity
                    if dist < minDist and dist <= Config.aimMaxDistance and velocity.Y > -100 then
                        minDist = dist
                        nearestRoot = enemyRoot
                        targetVelocity = velocity
                    end
                end
            end
        end
    end

    if nearestRoot then
        local predictedPos = nearestRoot.Position + (targetVelocity * Config.aimPredRate)
        return nearestRoot, predictedPos, targetVelocity
    end
    return nil, nil, nil
end

-- Expose shared API for any external modules
getgenv().MoneyhubSharedCore = {
    getNearestTarget = getNearestTarget,
    getConn = function() return autoShootConnection end,
    setConn = function(v) autoShootConnection = v end,
}
local Shared = getgenv().MoneyhubSharedCore

------------------------------------------------------------
-- Auto-shoot core
------------------------------------------------------------
local function StartAutoShoot()
    -- Disconnect previous connection if any
    if autoShootConnection then
        pcall(function() autoShootConnection:Disconnect() end)
        autoShootConnection = nil
    end

    autoShootConnection = RunService.Heartbeat:Connect(function()
        local myChar = getMyChar()
        if not myChar then return end

        -- Auto-equip gun (press "2" key) if enabled and not holding anything
        if Config.autoEquip and not myChar:FindFirstChildOfClass("Tool") then
            local currentTime = os.clock()
            if (currentTime - lastEquipTime) >= Config.equipCooldown then
                lastEquipTime = currentTime
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
                end)
            end
        end

        if not Config.autoShoot then return end

        local currentTime = os.clock()
        if (currentTime - lastFireTime) < Config.fireRateCooldown then
            return
        end

        -- Find the ShootGun remote
        local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
        local ShootRemote = remotesFolder and remotesFolder:FindFirstChild("ShootGun")
        if not ShootRemote then return end

        -- Find the muzzle on our currently held gun
        local gunModel = myChar:FindFirstChild("Gun_Equip") or myChar:FindFirstChildOfClass("Tool")
        local muzzle = gunModel and gunModel:FindFirstChild("Muzzle", true)
        if not muzzle then return end

        local targetInstance, predictedPosition = Shared.getNearestTarget()
        if targetInstance and predictedPosition then
            lastFireTime = currentTime
            pcall(function()
                ShootRemote:FireServer(muzzle.WorldPosition, predictedPosition, targetInstance, predictedPosition)
            end)
        end
    end)
    track(autoShootConnection)
end

local function StopAutoShoot()
    if autoShootConnection then
        pcall(function() autoShootConnection:Disconnect() end)
        autoShootConnection = nil
    end
end

------------------------------------------------------------
-- ESP / Tracers
------------------------------------------------------------
local espHighlights = {}   -- player -> Highlight instance
local espTracers = {}      -- player -> Beam instance
local espAdornments = {}   -- aim target BoxHandleAdornment

local ROLE_COLORS = {
    Sheriff = Color3.fromRGB(70, 130, 255),
    Murderer = Color3.fromRGB(220, 20, 60),
    Innocent = Color3.fromRGB(180, 180, 180),
}

local function getRole(player)
    -- In MVS Duels, roles map to Team
    if not player or not player.Team then return "Innocent" end
    local name = player.Team.Name:lower()
    if name:find("sheriff") or name:find("blue") then return "Sheriff" end
    if name:find("murder") or name:find("red") then return "Murderer" end
    return "Innocent"
end

local function refreshESP()
    -- Remove orphaned ESP
    for player, hl in pairs(espHighlights) do
        if not player.Parent or not player.Character then
            pcall(function() hl:Destroy() end)
            espHighlights[player] = nil
        end
    end
    for player, beam in pairs(espTracers) do
        if not player.Parent or not player.Character then
            pcall(function() beam:Destroy() end)
            espTracers[player] = nil
        end
    end
    if not Config.playerESP and not Config.tracerESP then return end

    -- Add / update ESP for each player
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local role = getRole(player)
            local color = ROLE_COLORS[role] or Color3.fromRGB(180, 180, 180)

            if Config.playerESP then
                local hl = espHighlights[player]
                if not hl or not hl.Parent then
                    hl = Instance.new("Highlight")
                    hl.Name = "StealthESP"
                    hl.Adornee = player.Character
                    hl.FillTransparency = 0.55
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = player.Character
                    espHighlights[player] = hl
                end
                hl.FillColor = color
                hl.OutlineColor = color
            else
                if espHighlights[player] then
                    pcall(function() espHighlights[player]:Destroy() end)
                    espHighlights[player] = nil
                end
            end

            if Config.tracerESP then
                local beam = espTracers[player]
                local myRoot = getMyRoot()
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if myRoot and hrp then
                    if not beam or not beam.Parent then
                        local a0 = Instance.new("Attachment")
                        a0.Name = "StealthTracerA0"
                        a0.Parent = myRoot
                        local a1 = Instance.new("Attachment")
                        a1.Name = "StealthTracerA1"
                        a1.Parent = hrp
                        beam = Instance.new("Beam")
                        beam.Name = "StealthTracer"
                        beam.Attachment0 = a0
                        beam.Attachment1 = a1
                        beam.Width0 = 0.15
                        beam.Width1 = 0.15
                        beam.Color = ColorSequence.new(color)
                        beam.Transparency = NumberSequence.new(0.4)
                        beam.Parent = myRoot
                        espTracers[player] = beam
                    end
                    -- Update color in case role changed
                    beam.Color = ColorSequence.new(color)
                end
            else
                if espTracers[player] then
                    pcall(function()
                        local beam = espTracers[player]
                        if beam.Attachment0 then beam.Attachment0:Destroy() end
                        if beam.Attachment1 then beam.Attachment1:Destroy() end
                        beam:Destroy()
                    end)
                    espTracers[player] = nil
                end
            end
        end
    end
end

-- Aim target visualization
local function refreshAimViz()
    if not Config.showAimTarget then
        for _, ad in pairs(espAdornments) do pcall(function() ad:Destroy() end) end
        espAdornments = {}
        return
    end
    local target, predictedPos = getNearestTarget()
    -- Clear old
    for _, ad in pairs(espAdornments) do pcall(function() ad:Destroy() end) end
    espAdornments = {}
    if target then
        local ad = Instance.new("BoxHandleAdornment")
        ad.Adornee = target
        ad.AlwaysOnTop = true
        ad.ZIndex = 5
        ad.Size = target.Size + Vector3.new(0.5, 0.5, 0.5)
        ad.Color3 = Color3.fromRGB(255, 80, 80)
        ad.Transparency = 0.2
        ad.Parent = game:GetService("CoreGui")
        table.insert(espAdornments, ad)
    end
end

------------------------------------------------------------
-- Movement
------------------------------------------------------------
local noclipConn = nil
local function setNoclip(enabled)
    Config.noclip = enabled
    if enabled then
        if noclipConn then return end
        noclipConn = RunService.Stepped:Connect(function()
            local c = getMyChar()
            if c then
                for _, part in ipairs(c:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
        track(noclipConn)
    else
        if noclipConn then
            pcall(function() noclipConn:Disconnect() end)
            noclipConn = nil
        end
    end
end

local infiniteJumpConn = nil
local function setInfiniteJump(enabled)
    Config.infiniteJump = enabled
    if enabled then
        if infiniteJumpConn then return end
        infiniteJumpConn = game:GetService("UserInputService").JumpRequest:Connect(function()
            local h = getMyHum()
            if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
        end)
        track(infiniteJumpConn)
    else
        if infiniteJumpConn then
            pcall(function() infiniteJumpConn:Disconnect() end)
            infiniteJumpConn = nil
        end
    end
end

local walkSpeedConn = nil
local function setWalkSpeedLock(enabled)
    Config.walkSpeedLocked = enabled
    if enabled then
        if walkSpeedConn then walkSpeedConn:Disconnect() end
        walkSpeedConn = RunService.Heartbeat:Connect(function()
            local h = getMyHum()
            if h and h.WalkSpeed ~= Config.lockedWalkSpeed then
                pcall(function() h.WalkSpeed = Config.lockedWalkSpeed end)
            end
        end)
        track(walkSpeedConn)
    else
        if walkSpeedConn then
            pcall(function() walkSpeedConn:Disconnect() end)
            walkSpeedConn = nil
        end
    end
end

local jumpPowerConn = nil
local function setJumpPowerLock(enabled)
    Config.jumpPowerLocked = enabled
    if enabled then
        if jumpPowerConn then jumpPowerConn:Disconnect() end
        jumpPowerConn = RunService.Heartbeat:Connect(function()
            local h = getMyHum()
            if h and h.JumpPower ~= Config.lockedJumpPower then
                pcall(function() h.JumpPower = Config.lockedJumpPower end)
            end
        end)
        track(jumpPowerConn)
    else
        if jumpPowerConn then
            pcall(function() jumpPowerConn:Disconnect() end)
            jumpPowerConn = nil
        end
    end
end

------------------------------------------------------------
-- Anti-AFK
------------------------------------------------------------
local antiAfkConn = nil
local function setAntiAFK(enabled)
    Config.antiAfk = enabled
    if enabled then
        if antiAfkConn then return end
        antiAfkConn = LocalPlayer.Idled:Connect(function()
            pcall(function()
                local VirtualUser = game:GetService("VirtualUser")
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
        track(antiAfkConn)
    else
        if antiAfkConn then
            pcall(function() antiAfkConn:Disconnect() end)
            antiAfkConn = nil
        end
    end
end

------------------------------------------------------------
-- Cleanup
------------------------------------------------------------
function SELF.destroy()
    StopAutoShoot()
    setNoclip(false)
    setInfiniteJump(false)
    setWalkSpeedLock(false)
    setJumpPowerLock(false)
    setAntiAFK(false)
    for _, hl in pairs(espHighlights) do pcall(function() hl:Destroy() end) end
    espHighlights = {}
    for _, beam in pairs(espTracers) do
        pcall(function()
            if beam.Attachment0 then beam.Attachment0:Destroy() end
            if beam.Attachment1 then beam.Attachment1:Destroy() end
            beam:Destroy()
        end)
    end
    espTracers = {}
    for _, ad in pairs(espAdornments) do pcall(function() ad:Destroy() end) end
    espAdornments = {}
    for _, conn in ipairs(SELF.conns) do
        pcall(function() conn:Disconnect() end)
    end
    SELF.conns = {}
    if _G.__StealthMVSD == SELF then _G.__StealthMVSD = nil end
end

------------------------------------------------------------
-- Load Airflow UI
------------------------------------------------------------
local Airflow = loadstring(game:HttpGet("https://raw.githubusercontent.com/PookiePepelsss/Airflow-UI/refs/heads/main/Source.luau"))()
if not Airflow then
    warn("[Stealth] Failed to load Airflow UI for MVSDuel")
    return
end
local Toggles = Airflow.Flags

local gameName = "Murderers VS Sheriffs DUELS"
pcall(function()
    local info = MarketplaceService:GetProductInfo(12355337193)
    if info and info.Name then gameName = info.Name end
end)

local Window = Airflow:CreateWindow({
    Name = "Stealth | MVSD",
    ConfigurationSaving = { Enabled = true, FolderName = "Stealth", FileName = "mvsduel" },
    Icon = "solar:shield-keyhole-bold-duotone",
    ToggleUIKeybind = "RightShift",
})

------------------------------------------------------------
-- Main tab
------------------------------------------------------------
local MainTab = Window:CreateTab({ Name = "Main", Desc = "Core combat features", Icon = "zap" })

MainTab:CreateSection("Auto Combat")
MainTab:CreateToggle({
    Name = "Auto Kill All (Gun)",
    Desc = "Auto-fires ShootGun remote at the nearest enemy's predicted position.",
    CurrentValue = false,
    Flag = "AutoShoot",
    Callback = function(v)
        Config.autoShoot = v
        Toggles.AutoShoot.Value = v
        if v then
            StartAutoShoot()
        elseif not Config.autoEquip then
            StopAutoShoot()
        end
    end,
})
MainTab:CreateToggle({
    Name = "Auto Equip Gun",
    Desc = "Auto-presses the '2' key to equip your gun when not holding a tool.",
    CurrentValue = false,
    Flag = "AutoEquip",
    Callback = function(v)
        Config.autoEquip = v
        Toggles.AutoEquip.Value = v
        if v then
            StartAutoShoot()
        elseif not Config.autoShoot then
            StopAutoShoot()
        end
    end,
})

MainTab:CreateSection("Aim Tuning")
MainTab:CreateSlider({
    Name = "Max Target Distance",
    Desc = "How far away an enemy can be before we ignore them.",
    Range = { 50, 2000 },
    Increment = 25,
    Suffix = " studs",
    CurrentValue = 500,
    Flag = "AimMaxDistance",
    Callback = function(v) Config.aimMaxDistance = v end,
})
MainTab:CreateSlider({
    Name = "Prediction Rate",
    Desc = "How much we lead the target by their velocity. Higher = more lead.",
    Range = { 0.0, 0.5 },
    Increment = 0.005,
    CurrentValue = 0.135,
    Flag = "AimPredRate",
    Callback = function(v) Config.aimPredRate = v end,
})
MainTab:CreateSlider({
    Name = "Fire Rate Cooldown",
    Desc = "Minimum seconds between shots. Lower = faster firing (may get kicked).",
    Range = { 0.05, 0.5 },
    Increment = 0.01,
    Suffix = " s",
    CurrentValue = 0.11,
    Flag = "FireRate",
    Callback = function(v) Config.fireRateCooldown = v end,
})
MainTab:CreateSlider({
    Name = "Equip Cooldown",
    Desc = "How often to retry pressing '2' if not holding a tool.",
    Range = { 0.1, 2.0 },
    Increment = 0.1,
    Suffix = " s",
    CurrentValue = 0.5,
    Flag = "EquipCooldown",
    Callback = function(v) Config.equipCooldown = v end,
})
MainTab:CreateToggle({
    Name = "Show Aim Target",
    Desc = "Draw a red box around the current auto-shoot target.",
    CurrentValue = false,
    Flag = "ShowAimTarget",
    Callback = function(v)
        Config.showAimTarget = v
        Toggles.ShowAimTarget.Value = v
    end,
})

------------------------------------------------------------
-- ESP tab
------------------------------------------------------------
local ESPTab = Window:CreateTab({ Name = "ESP", Desc = "Visual highlights", Icon = "eye" })
ESPTab:CreateSection("Player ESP")
ESPTab:CreateToggle({
    Name = "Player ESP (Highlights)",
    Desc = "Highlight every player through walls. Red = Murderer, Blue = Sheriff, Gray = Innocent.",
    CurrentValue = false,
    Flag = "PlayerESP",
    Callback = function(v)
        Config.playerESP = v
        Toggles.PlayerESP.Value = v
    end,
})
ESPTab:CreateToggle({
    Name = "Tracers (Beams)",
    Desc = "Draw a colored beam from you to each player.",
    CurrentValue = false,
    Flag = "TracerESP",
    Callback = function(v)
        Config.tracerESP = v
        Toggles.TracerESP.Value = v
    end,
})

-- ESP refresh loop
task.spawn(function()
    while _G.__StealthMVSD == SELF do
        pcall(refreshESP)
        pcall(refreshAimViz)
        task.wait(0.5)
    end
end)

------------------------------------------------------------
-- Movement tab
------------------------------------------------------------
local MovementTab = Window:CreateTab({ Name = "Movement", Desc = "Character modifiers", Icon = "wind" })
MovementTab:CreateSection("Movement")
MovementTab:CreateToggle({
    Name = "Noclip",
    Desc = "Walk through walls. Disable before round end to avoid suspicion.",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v) setNoclip(v) end,
})
MovementTab:CreateToggle({
    Name = "Infinite Jump",
    Desc = "Jump again in mid-air.",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(v) setInfiniteJump(v) end,
})

MovementTab:CreateSection("Walk Speed")
MovementTab:CreateToggle({
    Name = "Lock Walk Speed",
    Desc = "Re-apply walk speed if the game resets it.",
    CurrentValue = false,
    Flag = "LockWalkSpeed",
    Callback = function(v) setWalkSpeedLock(v) end,
})
MovementTab:CreateSlider({
    Name = "Walk Speed Value",
    Range = { 16, 200 },
    Increment = 1,
    Suffix = " sps",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v) Config.lockedWalkSpeed = v end,
})

MovementTab:CreateSection("Jump Power")
MovementTab:CreateToggle({
    Name = "Lock Jump Power",
    Desc = "Re-apply jump power if the game resets it.",
    CurrentValue = false,
    Flag = "LockJumpPower",
    Callback = function(v) setJumpPowerLock(v) end,
})
MovementTab:CreateSlider({
    Name = "Jump Power Value",
    Range = { 50, 500 },
    Increment = 1,
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v) Config.lockedJumpPower = v end,
})

------------------------------------------------------------
-- Utilities tab
------------------------------------------------------------
local UtilitiesTab = Window:CreateTab({ Name = "Utilities", Desc = "Misc features", Icon = "wrench" })
UtilitiesTab:CreateSection("Server Utilities")
UtilitiesTab:CreateToggle({
    Name = "Anti-AFK",
    Desc = "Prevents being kicked for inactivity.",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v) setAntiAFK(v) end,
})
UtilitiesTab:CreateButton({
    Name = "Copy Discord Invite",
    Desc = "Copies the Stealth Discord link to your clipboard.",
    Callback = function()
        pcall(function() setclipboard("https://discord.gg/hqE5drDHF7") end)
        Airflow:Notify({
            Title = "Stealth | MVSD",
            Content = "Discord invite copied!",
            Duration = 3,
            Type = "Success",
        })
    end,
})
UtilitiesTab:CreateButton({
    Name = "Unload Stealth",
    Desc = "Closes the UI and removes all overlays.",
    Callback = function()
        if SELF.destroy then SELF.destroy() end
        Window:Destroy()
    end,
})

------------------------------------------------------------
-- Cleanup hook on window destroy
------------------------------------------------------------
local origDestroy = Window.Destroy
function Window:Destroy(...)
    if SELF.destroy then SELF.destroy() end
    if origDestroy then return origDestroy(self, ...) end
end

------------------------------------------------------------
-- Welcome
------------------------------------------------------------
Airflow:Notify({
    Title = "Stealth | MVSD",
    Content = gameName .. " loaded! Press RightShift to toggle the UI.",
    Duration = 5,
    Type = "Success",
})

print("[Stealth] Loaded " .. gameName .. " via Airflow")

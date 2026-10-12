-- [[ Stealth | Murderers VS Sheriffs DUELS ]]
--
-- Original: Auto-shoot script by luhscripter (Rayfield UI)
-- Converted to Library UI for Stealth Hub.
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
                    hl.Name = "Catmio Reborn"
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
                        a0.Name = "Catmio Reborn"
                        a0.Parent = myRoot
                        local a1 = Instance.new("Attachment")
                        a1.Name = "Catmio Reborn"
                        a1.Parent = hrp
                        beam = Instance.new("Beam")
                        beam.Name = "Catmio Reborn"
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
-- Load Library UI
------------------------------------------------------------

-- =============================================================
-- Obsidian UI Wrapper (provides Library-compatible API)
-- =============================================================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Naellx/ObsidianUltra/main/Library.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Naellx/ObsidianUltra/main/addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Naellx/ObsidianUltra/main/addons/ThemeManager.lua"))()

-- Library uses Library.Flags and Library.Windows
Library.Flags = Library.Flags or {}
Library.Windows = Library.Windows or {}

-- Wrap CreateWindow to return a window with Library-style methods
local _origCreateWindow = Library.CreateWindow
Library.CreateWindow = function(self, opts)
    -- Library passes {Name=..., Icon=..., ToggleUIKeybind=...}
    -- Obsidian passes {Title=..., Footer=...}
    local winOpts = {}
    if type(opts) == "string" then
        winOpts.Title = opts
    elseif type(opts) == "table" then
        winOpts.Title = opts.Name or opts.Title or "Stealth"
        if opts.Footer then winOpts.Footer = opts.Footer end
        if opts.Icon then winOpts.Icon = opts.Icon end
    end
    local win = _origCreateWindow(self, winOpts)
    
    -- Wrap AddTab → returns tab with CreateSection/CreateToggle etc.
    local _origAddTab = win.AddTab or win.Tab
    function win:AddTab(name, ...)
        local tab
        if type(name) == "table" then
            tab = _origAddTab(self, name)
        else
            tab = _origAddTab(self, { Name = name })
        end
        return _wrapTab(tab)
    end
    function win:CreateTab(opts)
        if type(opts) == "string" then
            return self:AddTab(opts)
        end
        return self:AddTab(opts.Name or "Tab")
    end
    function win:Notify(opts)
        Library:Notify({ Title = opts.Title or opts.Name or "", Description = opts.Content or opts.Description or "", Time = opts.Duration or 5 })
    end
    function win:Destroy()
        if win.Unload then win:Unload() end
    end
    function win:Toggle() end
    return win
end

function _wrapTab(tab)
    local wrapper = {}
    wrapper._tab = tab
    
    function wrapper:CreateSection(name)
        return tab:AddLeftGroupbox(name)
    end
    wrapper.AddLeftGroupbox = wrapper.CreateSection
    wrapper.AddRightGroupbox = function(self, name) return tab:AddRightGroupbox(name) end
    
    function wrapper:CreateToggle(opts)
        local el = tab:AddLeftGroupbox(opts.Name or ""):AddToggle(opts.Flag or "", {
            Text = opts.Name or opts.Text or "",
            Default = opts.CurrentValue or false,
        })
        if opts.Callback then
            el:OnChanged(function() opts.Callback(el.Value) end)
        end
        return el
    end
    function wrapper:AddToggle(flag, opts)
        local el = tab:AddLeftGroupbox(opts.Text or ""):AddToggle(flag, {
            Text = opts.Text or "",
            Default = opts.Default or false,
        })
        return el
    end
    
    function wrapper:CreateSlider(opts)
        local el = tab:AddLeftGroupbox(opts.Name or ""):AddSlider(opts.Flag or "", {
            Text = opts.Name or "",
            Min = (opts.Range and opts.Range[1]) or 0,
            Max = (opts.Range and opts.Range[2]) or 100,
            Default = opts.CurrentValue or 0,
            Suffix = opts.Suffix or "",
        })
        if opts.Callback then
            el:OnChanged(function() opts.Callback(el.Value) end)
        end
        return el
    end
    function wrapper:AddSlider(flag, opts)
        local el = tab:AddLeftGroupbox(opts.Text or ""):AddSlider(flag, {
            Text = opts.Text or "",
            Min = opts.Min or 0,
            Max = opts.Max or 100,
            Default = opts.Default or 0,
            Suffix = opts.Suffix or "",
        })
        return el
    end
    
    function wrapper:CreateDropdown(opts)
        local el = tab:AddLeftGroupbox(opts.Name or ""):AddDropdown(opts.Flag or "", {
            Text = opts.Name or "",
            Values = opts.Options or {},
            Default = opts.CurrentOption or (opts.Options and opts.Options[1]) or nil,
        })
        if opts.Callback then
            el:OnChanged(function() opts.Callback(el.Value) end)
        end
        return el
    end
    function wrapper:AddDropdown(flag, opts)
        local el = tab:AddLeftGroupbox(opts.Text or ""):AddDropdown(flag, {
            Text = opts.Text or "",
            Values = opts.Values or {},
            Default = opts.Default,
        })
        return el
    end
    
    function wrapper:CreateColorPicker(opts)
        local el = tab:AddLeftGroupbox(opts.Name or ""):AddColorPicker(opts.Flag or "", {
            Text = opts.Name or "",
            Default = opts.Color or opts.Default or Color3.fromRGB(255,255,255),
        })
        return el
    end
    function wrapper:AddColorPicker(flag, opts)
        local el = tab:AddLeftGroupbox(opts.Text or ""):AddColorPicker(flag, {
            Text = opts.Text or "",
            Default = opts.Default or Color3.fromRGB(255,255,255),
        })
        return el
    end
    
    function wrapper:CreateInput(opts)
        local el = tab:AddLeftGroupbox(opts.Name or ""):AddInput(opts.Flag or "", {
            Text = opts.Name or "",
            Default = opts.CurrentValue or opts.Default or "",
            Placeholder = opts.PlaceholderText or "",
        })
        return el
    end
    function wrapper:AddInput(flag, opts)
        local el = tab:AddLeftGroupbox(opts.Text or ""):AddInput(flag, {
            Text = opts.Text or "",
            Default = opts.Default or "",
            Placeholder = opts.Placeholder or "",
        })
        return el
    end
    
    function wrapper:CreateKeybind(opts)
        local el = tab:AddLeftGroupbox(opts.Name or ""):AddKeyPicker(opts.Flag or "", {
            Text = opts.Name or "",
            Default = opts.CurrentKeybind or "MB2",
            Mode = opts.Mode or "Hold",
        })
        return el
    end
    function wrapper:AddKeybind(flag, opts)
        local el = tab:AddLeftGroupbox(opts.Text or ""):AddKeyPicker(flag, {
            Text = opts.Text or "",
            Default = opts.Default or "MB2",
        })
        return el
    end
    
    function wrapper:CreateButton(opts)
        tab:AddLeftGroupbox(opts.Name or ""):AddButton({
            Text = opts.Name or "",
            Func = opts.Callback or function() end,
        })
        return wrapper
    end
    function wrapper:AddButton(text, fn)
        tab:AddLeftGroupbox(""):AddButton({ Text = text, Func = fn or function() end })
        return wrapper
    end
    
    function wrapper:CreateLabel(opts)
        tab:AddLeftGroupbox(""):AddLabel(opts.Text or "")
        return wrapper
    end
    function wrapper:AddLabel(text)
        tab:AddLeftGroupbox(""):AddLabel(text)
        return wrapper
    end
    
    function wrapper:CreateParagraph(opts)
        tab:AddLeftGroupbox(opts.Title or ""):AddLabel(opts.Content or "")
        return wrapper
    end
    
    function wrapper:CreateDivider()
        return wrapper
    end
    
    return wrapper
end

-- Provide Toggles and Options tables (Linoria/Obsidian style)
Toggles = Library.Toggles or {}
Options = Library.Options or {}

-- Stub SaveManager/ThemeManager if they were niled
if not SaveManager then SaveManager = { LoadAutoloadConfig = function() end, SetLibrary = function() end, BuildConfigSequence = function() end } end
if not ThemeManager then ThemeManager = { ApplyToTab = function() end, SetLibrary = function() end, SetFolder = function() end, LoadDefault = function() end } end

if not Library then
    warn("[Stealth] Failed to load Library UI for MVSDuel")
    return
end
local Toggles = Library.Flags

local gameName = "Catmio Reborn"
pcall(function()
    local info = MarketplaceService:GetProductInfo(12355337193)
    if info and info.Name then gameName = info.Name end
end)

local Window = Library:CreateWindow({
    Name = "Catmio Reborn",
    ConfigurationSaving = { Enabled = true, FolderName = "Catmio Reborn", FileName = "Catmio Reborn" },
    Icon = "solar:shield-keyhole-bold-duotone",
    ToggleUIKeybind = "RightShift",
})

------------------------------------------------------------
-- Main tab
------------------------------------------------------------
local MainTab = Window:CreateTab({ Name = "Catmio Reborn", Desc = "Core combat features", Icon = "zap" })

MainTab:CreateSection("Auto Combat")
MainTab:CreateToggle({
    Name = "Catmio Reborn",
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
    Name = "Catmio Reborn",
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
    Name = "Catmio Reborn",
    Desc = "How far away an enemy can be before we ignore them.",
    Range = { 50, 2000 },
    Increment = 25,
    Suffix = " studs",
    CurrentValue = 500,
    Flag = "AimMaxDistance",
    Callback = function(v) Config.aimMaxDistance = v end,
})
MainTab:CreateSlider({
    Name = "Catmio Reborn",
    Desc = "How much we lead the target by their velocity. Higher = more lead.",
    Range = { 0.0, 0.5 },
    Increment = 0.005,
    CurrentValue = 0.135,
    Flag = "AimPredRate",
    Callback = function(v) Config.aimPredRate = v end,
})
MainTab:CreateSlider({
    Name = "Catmio Reborn",
    Desc = "Minimum seconds between shots. Lower = faster firing (may get kicked).",
    Range = { 0.05, 0.5 },
    Increment = 0.01,
    Suffix = " s",
    CurrentValue = 0.11,
    Flag = "FireRate",
    Callback = function(v) Config.fireRateCooldown = v end,
})
MainTab:CreateSlider({
    Name = "Catmio Reborn",
    Desc = "How often to retry pressing '2' if not holding a tool.",
    Range = { 0.1, 2.0 },
    Increment = 0.1,
    Suffix = " s",
    CurrentValue = 0.5,
    Flag = "EquipCooldown",
    Callback = function(v) Config.equipCooldown = v end,
})
MainTab:CreateToggle({
    Name = "Catmio Reborn",
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
local ESPTab = Window:CreateTab({ Name = "Catmio Reborn", Desc = "Visual highlights", Icon = "eye" })
ESPTab:CreateSection("Player ESP")
ESPTab:CreateToggle({
    Name = "Catmio Reborn",
    Desc = "Highlight every player through walls. Red = Murderer, Blue = Sheriff, Gray = Innocent.",
    CurrentValue = false,
    Flag = "PlayerESP",
    Callback = function(v)
        Config.playerESP = v
        Toggles.PlayerESP.Value = v
    end,
})
ESPTab:CreateToggle({
    Name = "Catmio Reborn",
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
local MovementTab = Window:CreateTab({ Name = "Catmio Reborn", Desc = "Character modifiers", Icon = "wind" })
MovementTab:CreateSection("Movement")
MovementTab:CreateToggle({
    Name = "Catmio Reborn",
    Desc = "Walk through walls. Disable before round end to avoid suspicion.",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v) setNoclip(v) end,
})
MovementTab:CreateToggle({
    Name = "Catmio Reborn",
    Desc = "Jump again in mid-air.",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(v) setInfiniteJump(v) end,
})

MovementTab:CreateSection("Walk Speed")
MovementTab:CreateToggle({
    Name = "Catmio Reborn",
    Desc = "Re-apply walk speed if the game resets it.",
    CurrentValue = false,
    Flag = "LockWalkSpeed",
    Callback = function(v) setWalkSpeedLock(v) end,
})
MovementTab:CreateSlider({
    Name = "Catmio Reborn",
    Range = { 16, 200 },
    Increment = 1,
    Suffix = " sps",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v) Config.lockedWalkSpeed = v end,
})

MovementTab:CreateSection("Jump Power")
MovementTab:CreateToggle({
    Name = "Catmio Reborn",
    Desc = "Re-apply jump power if the game resets it.",
    CurrentValue = false,
    Flag = "LockJumpPower",
    Callback = function(v) setJumpPowerLock(v) end,
})
MovementTab:CreateSlider({
    Name = "Catmio Reborn",
    Range = { 50, 500 },
    Increment = 1,
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v) Config.lockedJumpPower = v end,
})

------------------------------------------------------------
-- Utilities tab
------------------------------------------------------------
local UtilitiesTab = Window:CreateTab({ Name = "Catmio Reborn", Desc = "Misc features", Icon = "wrench" })
UtilitiesTab:CreateSection("Server Utilities")
UtilitiesTab:CreateToggle({
    Name = "Catmio Reborn",
    Desc = "Prevents being kicked for inactivity.",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v) setAntiAFK(v) end,
})
UtilitiesTab:CreateButton({
    Name = "Catmio Reborn",
    Desc = "Copies the Stealth Discord link to your clipboard.",
    Callback = function()
        pcall(function() setclipboard("https://discord.gg/hqE5drDHF7") end)
        Library:Notify({
            Title = "Catmio Reborn",
            Content = "Discord invite copied!",
            Duration = 3,
            Type = "Success",
        })
    end,
})
UtilitiesTab:CreateButton({
    Name = "Catmio Reborn",
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
Library:Notify({
    Title = "Catmio Reborn",
    Content = gameName .. " loaded! Press RightShift to toggle the UI.",
    Duration = 5,
    Type = "Success",
})

print("[Stealth] Loaded " .. gameName .. " via Library")

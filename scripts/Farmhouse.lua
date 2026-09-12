-- [[ Stealth | Chapter 1 (FARMHOUSE) ]]
--
-- Original: Ouroboros Hub @hidevin (ObsidianUltra)
-- Converted to WindUI for Stealth Hub.
-- Discord: discord.gg/hqE5drDHF7
--
-- GameId 10756011174 | PlaceId 108628039999641

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

------------------------------------------------------------
-- 2. Load WindUI
------------------------------------------------------------
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

_elevateIdentity()

------------------------------------------------------------
-- 3. State tables (mirror ObsidianUltra Toggles/Options pattern
--    so the automation logic reads Toggles.X.Value / Options.X.Value)
------------------------------------------------------------
local Toggles = {}
local Options = {}
local Library = {
    Toggles = Toggles,
    Options = Options,
    Unloaded = false,
    ShowCustomCursor = true,
}

function Library:Notify(opts)
    WindUI:Notify({
        Title = opts.Title or "Stealth",
        Content = opts.Description or "",
        Duration = opts.Time or 3,
        Icon = "solar:info-circle-bold",
    })
end

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    if self._onUnload then self._onUnload() end
    pcall(function() self._window:Destroy() end)
end

function Library:OnUnload(fn)
    self._onUnload = fn
end

------------------------------------------------------------
-- 4. Services & game refs
------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

local gameName = "Chapter 1 (FARMHOUSE)"

-- Replicated refs
local NeedleHaystack = ReplicatedStorage:WaitForChild("NeedleHaystack")
local Config = require(NeedleHaystack:WaitForChild("Config"))
local UpgradeConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Configs"):WaitForChild("UpgradeConfig"))
local BuyUpgrade = NeedleHaystack:WaitForChild("BuyUpgrade")
local BuyShopItem = NeedleHaystack:WaitForChild("BuyShopItem")
local PickHay = NeedleHaystack:WaitForChild("PickHay")
local PickDroppedHay = NeedleHaystack:WaitForChild("PickDroppedHay")
local SellHay = NeedleHaystack:WaitForChild("SellHay")
local CollectGem = NeedleHaystack:WaitForChild("CollectGem")
local DeployDrone = NeedleHaystack:WaitForChild("DeployDrone")
local PitchforkDig = NeedleHaystack:WaitForChild("PitchforkDig")
local TntAction = NeedleHaystack:WaitForChild("TntAction")
local VacuumAction = NeedleHaystack:WaitForChild("VacuumAction")
local NeedleHandIn = NeedleHaystack:WaitForChild("NeedleHandIn")

local BarnShop = Workspace:WaitForChild("BarnShop")
local DroppedHayFolder = Workspace:FindFirstChild("DroppedHay")
local GemsClientFolder = Workspace:FindFirstChild("GemsClient")

------------------------------------------------------------
-- 5. Create WindUI window
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

Library._window = Window

------------------------------------------------------------
-- 6. Helper to register toggle/slider/dropdown into Toggles/Options
------------------------------------------------------------
local function registerToggle(id, default)
    Toggles[id] = { Value = default }
end

local function registerOption(id, default)
    Options[id] = { Value = default }
end

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

local FarmingSection = Window:Section({ Title = "Farming" })
local CollectingTab = FarmingSection:Tab({
    Title = "Collecting",
    Icon = "solar:wheat-bold",
    IconShape = "Square",
    Border = true,
})
local SellingTab = FarmingSection:Tab({
    Title = "Selling",
    Icon = "solar:hand-money-bold",
    IconShape = "Square",
    Border = true,
})
local ToolsTab = FarmingSection:Tab({
    Title = "Tools",
    Icon = "solar:hammer-bold",
    IconShape = "Square",
    Border = true,
})
local NeedleTab = FarmingSection:Tab({
    Title = "Needle",
    Icon = "solar:magnifer-bold",
    IconShape = "Square",
    Border = true,
})

local InvSection = Window:Section({ Title = "Inventory" })
local ShopTab = InvSection:Tab({
    Title = "Shop",
    Icon = "solar:cart-large-bold",
    IconShape = "Square",
    Border = true,
})
local UpgradesTab = InvSection:Tab({
    Title = "Upgrades",
    Icon = "solar:graph-up-bold",
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
-- 8. Helpers (from original script, unchanged)
------------------------------------------------------------
local function getCash()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    local cash = ls and ls:FindFirstChild("Cash")
    return cash and cash.Value or 0
end
local function getGems()
    return tonumber(LocalPlayer:GetAttribute("Gems")) or 0
end
local function getHayHeld()
    local v = LocalPlayer:GetAttribute("HayHeld")
    if v ~= nil then return tonumber(v) or 0 end
    return 0
end
local function getHayCapacity()
    return tonumber(LocalPlayer:GetAttribute("HayCapacity")) or 25
end
local function owns(attr) return LocalPlayer:GetAttribute(attr) == true end

local function findClosestHay()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:GetAttribute("HayId") and inst:IsA("BasePart") and inst.Parent then
            local d = (inst.Position - hrp.Position).Magnitude
            if d < bestDist and d < 30 then
                bestDist = d
                best = inst
            end
        end
    end
    return best
end

local function getGrabCandidates(centerPart)
    local radius = tonumber(LocalPlayer:GetAttribute("HayGrabRadius")) or 0
    if radius <= 0 then return {} end
    local out = {}
    if not centerPart then return out end
    local cp = centerPart.Position
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst ~= centerPart and inst:GetAttribute("HayId") and inst:IsA("BasePart") then
            if (inst.Position - cp).Magnitude <= radius + 1 then
                table.insert(out, inst:GetAttribute("HayId"))
                if #out >= 6 then break end
            end
        end
    end
    return out
end

local function findClosestDropped()
    if not DroppedHayFolder then DroppedHayFolder = Workspace:FindFirstChild("DroppedHay") end
    if not DroppedHayFolder then return nil end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, 28
    for _, m in ipairs(DroppedHayFolder:GetChildren()) do
        local part = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart")
        if part then
            local d = (part.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                best = part.Parent:IsA("BasePart") and part.Parent or m
            end
        end
    end
    return best
end

local function findClosestGem()
    if not GemsClientFolder then GemsClientFolder = Workspace:FindFirstChild("GemsClient") end
    local root = GemsClientFolder or Workspace
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist, bestId = nil, 35, nil
    for _, mdl in ipairs(root:GetDescendants()) do
        if mdl:IsA("BasePart") and mdl:GetAttribute("GemId") then
            local d = (mdl.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                best = mdl
                bestId = mdl:GetAttribute("GemId")
            end
        end
    end
    if best and bestId then return best, bestId end
    for _, mdl in ipairs(Workspace:GetDescendants()) do
        if mdl:GetAttribute("GemId") and mdl:IsA("BasePart") then
            local d = (mdl.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                best = mdl
                bestId = mdl:GetAttribute("GemId")
            end
        end
    end
    if best then return best, bestId end
    return nil, nil
end

local function isBagFull()
    return getHayHeld() >= getHayCapacity()
end

local function getNearestSellPart()
    local CollectionService = game:GetService("CollectionService")
    local camPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or (LocalPlayer.Character and LocalPlayer.Character:GetPivot().Position or Vector3.new(0,0,0))
    local best, bestDist = nil, math.huge
    for _, part in ipairs(CollectionService:GetTagged(Config.SELL_PART_NAME)) do
        if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
            local d = (part.Position - camPos).Magnitude
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local cd = (part.Position - hrp.Position).Magnitude
                d = math.min(d, cd)
            end
            if d < bestDist then
                bestDist = d
                best = part
            end
        end
    end
    if not best then
        for _, inst in ipairs(workspace.SellModel:GetDescendants()) do
            if inst.Name == "SellPart" and inst:IsA("BasePart") then
                return inst
            end
        end
    end
    return best
end

local function trySell()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local sellPart = getNearestSellPart()
    if hrp and sellPart then
        local dist = (hrp.Position - sellPart.Position).Magnitude
        if dist > 14 then
            local target = sellPart.CFrame + Vector3.new(0, 3, 2)
            hrp.CFrame = target
            if workspace.CurrentCamera then
                workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, sellPart.Position)
            end
            task.wait(0.25)
        else
            if workspace.CurrentCamera then
                pcall(function()
                    workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, sellPart.Position)
                end)
            end
            task.wait(0.05)
        end
    end
    local ok, err = pcall(function() SellHay:FireServer() end)
    if not ok then
        Library:Notify({Title="Sell Failed", Description=tostring(err), Time=2})
    end
    task.spawn(function()
        local before = getHayHeld()
        task.wait(0.6)
        if before > 0 and getHayHeld() == before and hrp and sellPart then
            hrp.CFrame = sellPart.CFrame + Vector3.new(0, 4, 0)
            task.wait(0.2)
            pcall(function() SellHay:FireServer() end)
        end
    end)
    task.spawn(function()
        task.wait(1.0)
        local needReturn = false
        if Toggles.AutoPickHay and Toggles.AutoPickHay.Value then needReturn = true end
        if Toggles.AutoCollectDroppedHay and Toggles.AutoCollectDroppedHay.Value then needReturn = true end
        if Toggles.AutoCollectGems and Toggles.AutoCollectGems.Value then needReturn = true end
        if Toggles.AutoVacuumCollect and Toggles.AutoVacuumCollect.Value then needReturn = true end
        if Toggles.AutoVacuum and Toggles.AutoVacuum.Value then needReturn = true end
        if Toggles.AutoUsePitchfork and Toggles.AutoUsePitchfork.Value then needReturn = true end
        if Toggles.AutoFindNeedle and Toggles.AutoFindNeedle.Value then needReturn = true end
        if needReturn and getHayHeld() == 0 then
            local pile = Config.PILE_CENTER
            local hrp2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp2 and (hrp2.Position - pile).Magnitude > 22 then
                hrp2.CFrame = CFrame.new(pile + Vector3.new(math.random(-2,2), 5, math.random(-2,2)))
                if workspace.CurrentCamera then
                    workspace.CurrentCamera.CFrame = CFrame.new(hrp2.Position + Vector3.new(0,4,0), pile)
                end
            end
        end
    end)
end

------------------------------------------------------------
-- 9. MAIN TAB
------------------------------------------------------------
MainTab:Section({ Title = "Dashboard" })
MainTab:Section({ Title = "Game: " .. gameName, TextTransparency = 0.35 })
MainTab:Section({ Title = "Hub: Stealth", TextTransparency = 0.35 })
MainTab:Section({ Title = "Toggle UI: RightShift or floating button", TextTransparency = 0.35 })

MainTab:Space({ Columns = 1 })
MainTab:Section({ Title = "Session" })

local sessionLabel
MainTab:Section({ Title = "0s elapsed", TextTransparency = 0.35 })

task.spawn(function()
    local s=0
    while true do
        task.wait(1)
        if Library.Unloaded then break end
        s+=1
        -- WindUI sections are static; we can't update text in place easily.
        -- Skip live session update (would need a label element with :SetText).
    end
end)

MainTab:Space({ Columns = 1 })
MainTab:Section({ Title = "Discord" })
MainTab:Button({
    Title = "Copy Discord",
    Desc = "discord.gg/hqE5drDHF7",
    Icon = "solar:chat-round-dots-bold",
    Color = Color3.fromHex("#5865F2"),
    Justify = "Left",
    IconAlign = "Left",
    Callback = function()
        pcall(function() setclipboard("https://discord.gg/hqE5drDHF7") end)
        WindUI:Notify({
            Title = "Discord",
            Content = "Invite copied to clipboard!",
            Duration = 3,
            Icon = "solar:chat-round-dots-bold",
        })
    end,
})

MainTab:Space({ Columns = 1 })
MainTab:Section({ Title = "Status" })
MainTab:Section({ Title = "Farming & Inventory tabs hold all automation.", TextTransparency = 0.35 })
MainTab:Section({ Title = "Settings holds Config & Anti-AFK.", TextTransparency = 0.35 })

------------------------------------------------------------
-- 10. COLLECTING TAB
------------------------------------------------------------
CollectingTab:Section({ Title = "Resource Collecting" })

registerToggle("AutoPickHay", false)
CollectingTab:Toggle({
    Title = "Auto Pick Hay",
    Desc = "Pick hay from stack continuously",
    Default = false,
    Callback = function(v) Toggles.AutoPickHay.Value = v end,
})

registerToggle("AutoCollectDroppedHay", false)
CollectingTab:Toggle({
    Title = "Auto Collect Dropped Hay",
    Default = false,
    Callback = function(v) Toggles.AutoCollectDroppedHay.Value = v end,
})

registerToggle("AutoCollectGems", false)
CollectingTab:Toggle({
    Title = "Auto Collect Gems",
    Default = false,
    Callback = function(v) Toggles.AutoCollectGems.Value = v end,
})

registerToggle("AutoVacuumCollect", false)
CollectingTab:Toggle({
    Title = "Auto Vacuum Collect",
    Desc = "Uses Vacuum Start/Stop (requires Vacuum tool)",
    Default = false,
    Callback = function(v) Toggles.AutoVacuumCollect.Value = v end,
})

registerOption("CollectInterval", 1)
CollectingTab:Slider({
    Title = "Loop Interval",
    Default = 1,
    Min = 0.1,
    Max = 3,
    Rounding = 1,
    Suffix = "s",
    Callback = function(v) Options.CollectInterval.Value = v end,
})

CollectingTab:Space({ Columns = 1 })
CollectingTab:Section({ Title = "Vacuum needs VacuumOwned. Gems within 35 studs.", TextTransparency = 0.35 })

------------------------------------------------------------
-- 11. SELLING TAB
------------------------------------------------------------
SellingTab:Section({ Title = "Selling" })

registerToggle("AutoSellHay", false)
SellingTab:Toggle({
    Title = "Auto Sell Hay",
    Default = false,
    Callback = function(v) Toggles.AutoSellHay.Value = v end,
})

registerOption("SellThreshold", 25)
SellingTab:Slider({
    Title = "Sell When Hay >=",
    Default = 25,
    Min = 1,
    Max = 250,
    Rounding = 0,
    Callback = function(v) Options.SellThreshold.Value = v end,
})

registerToggle("SellOnlyIfFull", false)
SellingTab:Toggle({
    Title = "Only Sell If Full",
    Default = false,
    Callback = function(v) Toggles.SellOnlyIfFull.Value = v end,
})

SellingTab:Space({ Columns = 1 })
SellingTab:Section({ Title = "Fires SellHay:FireServer() near cow.", TextTransparency = 0.35 })
SellingTab:Section({ Title = "VacuumLoad also counts as held.", TextTransparency = 0.35 })

------------------------------------------------------------
-- 12. TOOLS TAB
------------------------------------------------------------
ToolsTab:Section({ Title = "Auto Tool Usage" })

registerToggle("AutoUseTNT", false)
ToolsTab:Toggle({
    Title = "Auto Use TNT",
    Desc = "Light & throw TNT on cooldown",
    Default = false,
    Callback = function(v) Toggles.AutoUseTNT.Value = v end,
})

registerToggle("AutoUsePitchfork", false)
ToolsTab:Toggle({
    Title = "Auto Use Pitchfork",
    Default = false,
    Callback = function(v) Toggles.AutoUsePitchfork.Value = v end,
})

registerToggle("AutoDeployDrone", false)
ToolsTab:Toggle({
    Title = "Auto Deploy Drone",
    Default = false,
    Callback = function(v) Toggles.AutoDeployDrone.Value = v end,
})

registerToggle("AutoVacuum", false)
ToolsTab:Toggle({
    Title = "Auto Vacuum (Loop)",
    Default = false,
    Callback = function(v) Toggles.AutoVacuum.Value = v end,
})

registerOption("ToolInterval", 1)
ToolsTab:Slider({
    Title = "Tool Interval",
    Default = 1,
    Min = 0.2,
    Max = 5,
    Rounding = 1,
    Suffix = "s",
    Callback = function(v) Options.ToolInterval.Value = v end,
})

ToolsTab:Space({ Columns = 1 })
ToolsTab:Section({ Title = "Requirements", TextTransparency = 0.5 })
ToolsTab:Section({ Title = "PitchforkOwned, TntOwned, DroneOwned, VacuumOwned required per tool.", TextTransparency = 0.35 })
ToolsTab:Section({ Title = "TNT cooldown & vacuum heat managed by server.", TextTransparency = 0.35 })

------------------------------------------------------------
-- 13. NEEDLE TAB
------------------------------------------------------------
NeedleTab:Section({ Title = "Needle" })

registerToggle("AutoFindNeedle", false)
NeedleTab:Toggle({
    Title = "Auto Find Needle",
    Desc = "Continuously pick around pile center to reveal needle",
    Default = false,
    Callback = function(v) Toggles.AutoFindNeedle.Value = v end,
})

registerToggle("AutoHandInNeedle", false)
NeedleTab:Toggle({
    Title = "Auto Hand In Needle",
    Desc = "Fires NeedleHandIn when near NPC",
    Default = false,
    Callback = function(v) Toggles.AutoHandInNeedle.Value = v end,
})

registerOption("NeedleInterval", 1)
NeedleTab:Slider({
    Title = "Needle Interval",
    Default = 1,
    Min = 0.2,
    Max = 3,
    Rounding = 1,
    Suffix = "s",
    Callback = function(v) Options.NeedleInterval.Value = v end,
})

NeedleTab:Space({ Columns = 1 })
NeedleTab:Section({ Title = "How Needle Works", TextTransparency = 0.5 })
NeedleTab:Section({ Title = "Needle spawns under hay. Removing hay reveals it.", TextTransparency = 0.35 })
NeedleTab:Section({ Title = "Pile center from Config.PILE_CENTER used for automation.", TextTransparency = 0.35 })

------------------------------------------------------------
-- 14. SHOP TAB
------------------------------------------------------------
ShopTab:Section({ Title = "Purchasing" })

registerOption("BuyToolsList", {})
ShopTab:Dropdown({
    Title = "Buy Tools Selection",
    Values = { "Pitchfork", "TNT", "Drone", "Vacuum", "Infinite Bag", "Capacity Bag" },
    Multi = true,
    Default = {},
    Callback = function(v)
        -- WindUI returns a table for multi-select
        Options.BuyToolsList.Value = v or {}
    end,
})

registerToggle("AutoBuyTools", false)
ShopTab:Toggle({
    Title = "Auto Buy Selected Tools",
    Default = false,
    Callback = function(v) Toggles.AutoBuyTools.Value = v end,
})

registerOption("BuyInterval", 1)
ShopTab:Slider({
    Title = "Buy Interval",
    Default = 1,
    Min = 0.5,
    Max = 5,
    Rounding = 1,
    Suffix = "s",
    Callback = function(v) Options.BuyInterval.Value = v end,
})

ShopTab:Space({ Columns = 1 })
ShopTab:Section({ Title = "Ownership", TextTransparency = 0.5 })
ShopTab:Section({ Title = "Attributes: PitchforkOwned, TntOwned, DroneOwned, VacuumOwned, InfiniteBagOwned", TextTransparency = 0.35 })

ShopTab:Space({ Columns = 1 })
ShopTab:Button({
    Title = "Check Ownership",
    Icon = "solar:check-circle-bold",
    Color = Color3.fromHex("#30FF6A"),
    Justify = "Left",
    IconAlign = "Left",
    Callback = function()
        local t = {}
        for _,k in ipairs({"PitchforkOwned","TntOwned","DroneOwned","VacuumOwned","InfiniteBagOwned","HayUpgradeCapacity"}) do
            table.insert(t, k..": "..tostring(LocalPlayer:GetAttribute(k)))
        end
        Library:Notify({Title="Ownership", Description=table.concat(t,"\n"), Time=4})
    end,
})

------------------------------------------------------------
-- 15. UPGRADES TAB
------------------------------------------------------------
UpgradesTab:Section({ Title = "Permanent (Gems)" })

registerToggle("UpgBagSize", false)
UpgradesTab:Toggle({
    Title = "Auto Upgrade Bag Size",
    Desc = "ExtraHoldAmount -> Gems 25,50,75,100,150,450",
    Default = false,
    Callback = function(v) Toggles.UpgBagSize.Value = v end,
})

registerToggle("UpgExtraTake", false)
UpgradesTab:Toggle({
    Title = "Auto Upgrade Hand Grab Amount",
    Default = false,
    Callback = function(v) Toggles.UpgExtraTake.Value = v end,
})

registerToggle("UpgGemValue", false)
UpgradesTab:Toggle({
    Title = "Auto Upgrade Gem Value",
    Default = false,
    Callback = function(v) Toggles.UpgGemValue.Value = v end,
})

registerToggle("UpgHayValue", false)
UpgradesTab:Toggle({
    Title = "Auto Upgrade Hay Value",
    Default = false,
    Callback = function(v) Toggles.UpgHayValue.Value = v end,
})

registerOption("PermInterval", 1)
UpgradesTab:Slider({
    Title = "Permanent Loop",
    Default = 1,
    Min = 0.5,
    Max = 5,
    Rounding = 1,
    Suffix = "s",
    Callback = function(v) Options.PermInterval.Value = v end,
})

UpgradesTab:Space({ Columns = 1 })
UpgradesTab:Section({ Title = "Hand Upgrades (Cash)" })

registerToggle("UpgHandSpeed", false)
UpgradesTab:Toggle({ Title = "Auto Hand Speed", Desc = "Speed track 0.55->0.3", Default = false, Callback = function(v) Toggles.UpgHandSpeed.Value = v end })

registerToggle("UpgHandGrab", false)
UpgradesTab:Toggle({ Title = "Auto Hand Grasp", Default = false, Callback = function(v) Toggles.UpgHandGrab.Value = v end })

registerToggle("UpgHandHold", false)
UpgradesTab:Toggle({ Title = "Auto Hand Hold", Default = false, Callback = function(v) Toggles.UpgHandHold.Value = v end })

UpgradesTab:Space({ Columns = 1 })
UpgradesTab:Section({ Title = "TNT Upgrades" })

registerToggle("UpgTntLuck", false)
UpgradesTab:Toggle({ Title = "Auto TNT Lucky Blast", Default = false, Callback = function(v) Toggles.UpgTntLuck.Value = v end })

registerToggle("UpgTntCooldown", false)
UpgradesTab:Toggle({ Title = "Auto TNT Cooldown", Default = false, Callback = function(v) Toggles.UpgTntCooldown.Value = v end })

registerToggle("UpgTntPower", false)
UpgradesTab:Toggle({ Title = "Auto TNT Power", Default = false, Callback = function(v) Toggles.UpgTntPower.Value = v end })

UpgradesTab:Space({ Columns = 1 })
UpgradesTab:Section({ Title = "Pitchfork Upgrades" })

registerToggle("UpgPitchCooldown", false)
UpgradesTab:Toggle({ Title = "Auto Pitchfork Cooldown", Default = false, Callback = function(v) Toggles.UpgPitchCooldown.Value = v end })

registerToggle("UpgPitchHold", false)
UpgradesTab:Toggle({ Title = "Auto Pitchfork Hold", Default = false, Callback = function(v) Toggles.UpgPitchHold.Value = v end })

registerToggle("UpgPitchSweep", false)
UpgradesTab:Toggle({ Title = "Auto Pitchfork Sweep", Default = false, Callback = function(v) Toggles.UpgPitchSweep.Value = v end })

UpgradesTab:Space({ Columns = 1 })
UpgradesTab:Section({ Title = "Drone Upgrades" })

registerToggle("UpgDroneSpeed", false)
UpgradesTab:Toggle({ Title = "Auto Drone Speed", Default = false, Callback = function(v) Toggles.UpgDroneSpeed.Value = v end })

registerToggle("UpgDroneGrab", false)
UpgradesTab:Toggle({ Title = "Auto Drone Grasp", Default = false, Callback = function(v) Toggles.UpgDroneGrab.Value = v end })

registerToggle("UpgDroneCapacity", false)
UpgradesTab:Toggle({ Title = "Auto Drone Capacity", Default = false, Callback = function(v) Toggles.UpgDroneCapacity.Value = v end })

UpgradesTab:Space({ Columns = 1 })
UpgradesTab:Section({ Title = "Vacuum Upgrades" })

registerToggle("UpgVacPower", false)
UpgradesTab:Toggle({ Title = "Auto Vacuum Power", Default = false, Callback = function(v) Toggles.UpgVacPower.Value = v end })

registerToggle("UpgVacCooling", false)
UpgradesTab:Toggle({ Title = "Auto Vacuum Cooling", Default = false, Callback = function(v) Toggles.UpgVacCooling.Value = v end })

registerToggle("UpgVacRuntime", false)
UpgradesTab:Toggle({ Title = "Auto Vacuum Runtime", Default = false, Callback = function(v) Toggles.UpgVacRuntime.Value = v end })

UpgradesTab:Space({ Columns = 1 })
UpgradesTab:Section({ Title = "Capacity" })

registerToggle("UpgCapacity", false)
UpgradesTab:Toggle({
    Title = "Auto Upgrade Carry Capacity",
    Desc = "25->250 cash upgrades",
    Default = false,
    Callback = function(v) Toggles.UpgCapacity.Value = v end,
})

UpgradesTab:Section({ Title = "Cash upgrades use BuyUpgrade with track names.", TextTransparency = 0.35 })

------------------------------------------------------------
-- 16. SETTINGS TAB
------------------------------------------------------------
SettingsTab:Section({ Title = "Menu" })

SettingsTab:Button({
    Title = "Unload Stealth",
    Desc = "Closes the UI and stops all automation.",
    Icon = "solar:close-circle-bold",
    Color = Color3.fromHex("#ff4830"),
    Justify = "Left",
    IconAlign = "Left",
    Callback = function()
        Library:Unload()
    end,
})

SettingsTab:Space({ Columns = 1 })
SettingsTab:Section({ Title = "System" })

registerToggle("AntiAFK", true)
SettingsTab:Toggle({
    Title = "Anti-AFK (jump every 5m)",
    Desc = "Enabled by default. Uses jump to keep alive.",
    Default = true,
    Callback = function(v) Toggles.AntiAFK.Value = v end,
})

------------------------------------------------------------
-- 17. Automation Logic (unchanged from original)
------------------------------------------------------------
local function waitInterval(optName, fallback)
    local v = Options[optName] and Options[optName].Value or fallback
    return tonumber(v) or fallback
end

local function ensureNearPileForPick()
    local pile = Config.PILE_CENTER
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local distToPile = (hrp.Position - pile).Magnitude
    if distToPile > 28 then
        hrp.CFrame = CFrame.new(pile + Vector3.new(math.random(-3,3), 5, math.random(-3,3)))
        if workspace.CurrentCamera then
            workspace.CurrentCamera.CFrame = CFrame.new(hrp.Position + Vector3.new(0,4,0), pile)
        end
        task.wait(0.25)
    end
end

local function teleportToPart(part, yOffset)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not part then return end
    local dist = (hrp.Position - part.Position).Magnitude
    if dist > 15 then
        hrp.CFrame = part.CFrame + Vector3.new(0, yOffset or 4, 1.5)
        if workspace.CurrentCamera then
            pcall(function() workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, part.Position) end)
        end
        task.wait(0.18)
    else
        if workspace.CurrentCamera then
            pcall(function() workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, part.Position) end)
        end
    end
end

-- Auto Pick Hay
task.spawn(function()
    while true do
        task.wait(waitInterval("CollectInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoPickHay and Toggles.AutoPickHay.Value then
            if not isBagFull() then
                local hay = findClosestHay()
                if not hay then
                    ensureNearPileForPick()
                    hay = findClosestHay()
                end
                if hay then
                    teleportToPart(hay, 4)
                    local id = hay:GetAttribute("HayId")
                    if id then
                        local candidates = getGrabCandidates(hay)
                        pcall(function() PickHay:FireServer(id, candidates) end)
                    else
                        pcall(function() PickDroppedHay:FireServer(hay) end)
                    end
                else
                    ensureNearPileForPick()
                end
            end
        end
    end
end)

-- Auto Collect Dropped Hay
task.spawn(function()
    while true do
        task.wait(waitInterval("CollectInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoCollectDroppedHay and Toggles.AutoCollectDroppedHay.Value then
            if not isBagFull() then
                local d = findClosestDropped()
                if not d then
                    ensureNearPileForPick()
                    d = findClosestDropped()
                end
                if d then
                    local part = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart")
                    if part then teleportToPart(part, 3) end
                    pcall(function() PickDroppedHay:FireServer(d) end)
                end
            end
        end
    end
end)

-- Auto Collect Gems
task.spawn(function()
    while true do
        task.wait(waitInterval("CollectInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoCollectGems and Toggles.AutoCollectGems.Value then
            local gemPart, id = findClosestGem()
            if not gemPart then
                ensureNearPileForPick()
                gemPart, id = findClosestGem()
            end
            if gemPart and id then
                teleportToPart(gemPart, 3)
                pcall(function() CollectGem:FireServer(id) end)
            end
        end
    end
end)

-- Auto Sell
task.spawn(function()
    while true do
        task.wait(1)
        if Library.Unloaded then break end
        if Toggles.AutoSellHay and Toggles.AutoSellHay.Value then
            local held = getHayHeld()
            local thresh = Options.SellThreshold and Options.SellThreshold.Value or 25
            local onlyFull = Toggles.SellOnlyIfFull and Toggles.SellOnlyIfFull.Value
            local should = false
            if onlyFull then should = isBagFull()
            else should = held >= thresh end
            if should and held > 0 then trySell() end
        end
    end
end)

-- Vacuum collect loop
do
    local vacActive = false
    task.spawn(function()
        while true do
            task.wait(waitInterval("CollectInterval",1))
            if Library.Unloaded then break end
            local want = Toggles.AutoVacuumCollect and Toggles.AutoVacuumCollect.Value
            local want2 = Toggles.AutoVacuum and Toggles.AutoVacuum.Value
            local should = want or want2
            if should and owns("VacuumOwned") then
                if not vacActive and not isBagFull() then
                    local hay = findClosestHay()
                    if not hay then ensureNearPileForPick() hay = findClosestHay() end
                    if hay then teleportToPart(hay, 5) end
                    pcall(function() VacuumAction:FireServer("Start") end)
                    vacActive = true
                elseif isBagFull() and vacActive then
                    pcall(function() VacuumAction:FireServer("Stop") end)
                    vacActive = false
                    trySell()
                end
            else
                if vacActive then pcall(function() VacuumAction:FireServer("Stop") end) vacActive=false end
            end
            if vacActive and LocalPlayer:GetAttribute("VacuumOverheated") then
                pcall(function() VacuumAction:FireServer("Stop") end) vacActive=false
                task.wait(0.5)
                ensureNearPileForPick()
            end
        end
    end)
end

-- Auto Use TNT
task.spawn(function()
    while true do
        task.wait(waitInterval("ToolInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoUseTNT and Toggles.AutoUseTNT.Value and owns("TntOwned") then
            local ok = not LocalPlayer:GetAttribute("NeedleInputLocked")
            if ok then
                pcall(function() TntAction:FireServer("light") end)
                task.wait(0.4)
                local cam = Workspace.CurrentCamera
                if cam then
                    local dir = cam.CFrame.LookVector * 40 + Vector3.new(0,8,0)
                    local cf = cam.CFrame
                    pcall(function() TntAction:FireServer("throw", cf, dir) end)
                end
            end
        end
    end
end)

-- Auto Use Pitchfork
task.spawn(function()
    while true do
        task.wait(waitInterval("ToolInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoUsePitchfork and Toggles.AutoUsePitchfork.Value and owns("PitchforkOwned") then
            local hay = findClosestHay()
            if not hay then ensureNearPileForPick() hay = findClosestHay() end
            if hay then teleportToPart(hay, 4) end
            local id = hay and hay:GetAttribute("HayId")
            if id then
                pcall(function() PitchforkDig:FireServer(id) end)
            else
                local fakeId = LocalPlayer:GetAttribute("HoveredHayId")
                if fakeId then
                    ensureNearPileForPick()
                    pcall(function() PitchforkDig:FireServer(fakeId) end)
                end
            end
        end
    end
end)

-- Auto Deploy Drone
task.spawn(function()
    while true do
        task.wait(waitInterval("ToolInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoDeployDrone and Toggles.AutoDeployDrone.Value and owns("DroneOwned") then
            if not LocalPlayer:GetAttribute("DroneDeployed") then
                pcall(function() DeployDrone:FireServer() end)
            end
        end
    end
end)

-- Needle loops
task.spawn(function()
    while true do
        task.wait(waitInterval("NeedleInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoFindNeedle and Toggles.AutoFindNeedle.Value then
            if not LocalPlayer:GetAttribute("NeedleRoundComplete") then
                local hay = findClosestHay()
                if not hay then ensureNearPileForPick() hay = findClosestHay() end
                if hay then
                    teleportToPart(hay, 4)
                    local id = hay:GetAttribute("HayId")
                    if id and not isBagFull() then
                        pcall(function() PickHay:FireServer(id, getGrabCandidates(hay)) end)
                    elseif isBagFull() then
                        trySell()
                    end
                else
                    ensureNearPileForPick()
                end
            end
        end
        if Toggles.AutoHandInNeedle and Toggles.AutoHandInNeedle.Value then
            local farmer = workspace:FindFirstChild("NPC") and workspace.NPC:FindFirstChild("Farmer_NPC")
            if farmer and farmer:GetPivot() then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - farmer:GetPivot().Position).Magnitude > 20 then
                    hrp.CFrame = farmer:GetPivot() * CFrame.new(0,0,4)
                    task.wait(0.2)
                end
            end
            pcall(function() NeedleHandIn:FireServer() end)
        end
    end
end)

-- Auto Buy Tools
task.spawn(function()
    while true do
        task.wait(waitInterval("BuyInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoBuyTools and Toggles.AutoBuyTools.Value then
            local sel = Options.BuyToolsList and Options.BuyToolsList.Value or {}
            local list = {}
            if typeof(sel) == "table" then
                for k,v in pairs(sel) do if v then table.insert(list, k) end end
                if #list==0 then for _,v in ipairs(sel) do table.insert(list, v) end end
            end
            for _, name in ipairs(list) do
                if name == "Pitchfork" and not owns("PitchforkOwned") then pcall(function() BuyShopItem:FireServer("Pitchfork") end)
                elseif name == "TNT" and not owns("TntOwned") then pcall(function() BuyShopItem:FireServer("Tnt") end)
                elseif name == "Drone" and not owns("DroneOwned") then pcall(function() BuyShopItem:FireServer("Drone") end)
                elseif name == "Vacuum" and not owns("VacuumOwned") then pcall(function() BuyShopItem:FireServer("Vacuum") end)
                elseif name == "Infinite Bag" and not owns("InfiniteBagOwned") then pcall(function() BuyShopItem:FireServer("InfiniteBag") end)
                elseif name == "Capacity Bag" then
                    local st = tonumber(LocalPlayer:GetAttribute("HayUpgradeCapacity")) or 1
                    local track = Config.UPGRADE_TRACKS["Capacity"]
                    if track and st < #track.Levels then
                        local cost = track.Levels[st+1].Cost
                        if getCash() >= (cost or 0) then pcall(function() BuyUpgrade:FireServer("Capacity") end) end
                    end
                end
            end
        end
    end
end)

-- Upgrade helpers
local function tryBuyTrack(trackName)
    local track = Config.UPGRADE_TRACKS[trackName]
    if not track then return end
    local cur = tonumber(LocalPlayer:GetAttribute("HayUpgrade"..trackName)) or 1
    if cur >= #track.Levels then return end
    local nxt = track.Levels[cur+1]
    if not nxt then return end
    local cost = nxt.Cost or 0
    if getCash() >= cost then
        pcall(function() BuyUpgrade:FireServer(trackName) end)
    end
end
local function tryBuyPermanent(id)
    local u = UpgradeConfig.getUpgrade(id)
    if not u then return end
    local cur = tonumber(LocalPlayer:GetAttribute("Upgrade"..id)) or 0
    local max = UpgradeConfig.getMaxLevel(u)
    if cur >= max then return end
    local price = UpgradeConfig.getPrice(u, cur)
    if price and getGems() >= price then
        pcall(function() BuyUpgrade:FireServer(id) end)
    end
end

-- Permanent upgrades loop
task.spawn(function()
    while true do
        task.wait(waitInterval("PermInterval",1))
        if Library.Unloaded then break end
        if Toggles.UpgBagSize and Toggles.UpgBagSize.Value then tryBuyPermanent("ExtraHoldAmount") end
        if Toggles.UpgExtraTake and Toggles.UpgExtraTake.Value then tryBuyPermanent("ExtraTakeAmount") end
        if Toggles.UpgGemValue and Toggles.UpgGemValue.Value then tryBuyPermanent("GemValue") end
        if Toggles.UpgHayValue and Toggles.UpgHayValue.Value then tryBuyPermanent("ExtraHayValuePercentage") end
    end
end)

-- Session upgrades loop
task.spawn(function()
    while true do
        task.wait(1.2)
        if Library.Unloaded then break end
        if Toggles.UpgCapacity and Toggles.UpgCapacity.Value then tryBuyTrack("Capacity") end
        if Toggles.UpgHandSpeed and Toggles.UpgHandSpeed.Value then tryBuyTrack("Speed") end
        if Toggles["UpgHandGrab"] and Toggles["UpgHandGrab"].Value then
            tryBuyTrack("Grab")
        end
        if Toggles.UpgHandHold and Toggles.UpgHandHold.Value then tryBuyTrack("HandHold") end
        if Toggles.UpgTntLuck and Toggles.UpgTntLuck.Value then tryBuyTrack("TntLuck") end
        if Toggles.UpgTntCooldown and Toggles.UpgTntCooldown.Value then tryBuyTrack("TntCooldown") end
        if Toggles.UpgTntPower and Toggles.UpgTntPower.Value then tryBuyTrack("TntPower") end
        if Toggles.UpgPitchCooldown and Toggles.UpgPitchCooldown.Value then tryBuyTrack("PitchforkCooldown") end
        if Toggles.UpgPitchHold and Toggles.UpgPitchHold.Value then tryBuyTrack("PitchforkHold") end
        if Toggles.UpgPitchSweep and Toggles.UpgPitchSweep.Value then tryBuyTrack("Pitchfork") end
        if Toggles.UpgDroneSpeed and Toggles.UpgDroneSpeed.Value then tryBuyTrack("DroneSpeed") end
        if Toggles.UpgDroneGrab and Toggles.UpgDroneGrab.Value then tryBuyTrack("DroneGrab") end
        if Toggles.UpgDroneCapacity and Toggles.UpgDroneCapacity.Value then tryBuyTrack("DroneCapacity") end
        if Toggles.UpgVacPower and Toggles.UpgVacPower.Value then tryBuyTrack("VacuumPower") end
        if Toggles.UpgVacCooling and Toggles.UpgVacCooling.Value then tryBuyTrack("VacuumCooling") end
        if Toggles.UpgVacRuntime and Toggles.UpgVacRuntime.Value then tryBuyTrack("VacuumRuntime") end
    end
end)

-- Anti-AFK
task.spawn(function()
    while true do
        task.wait(300)
        if Library.Unloaded then break end
        if Toggles.AntiAFK and Toggles.AntiAFK.Value then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) hum.Jump = true end
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end)

-- Safety: unload clean
Library:OnUnload(function()
    pcall(function() VacuumAction:FireServer("Stop") end)
    print("[Stealth] Unloaded - "..gameName)
end)

Library:Notify({
    Title = "Stealth",
    Description = gameName .. " loaded. Farming=collect/sell/tools | Inventory=shop/upgrades",
    Time = 5,
})
print("[Stealth] Loaded "..gameName.." via WindUI")
